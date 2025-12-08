#!/usr/bin/env python3
"""
Analyze Rails migrations and schema for index opportunities.
Detects foreign keys without indexes and queries that might benefit from indexes.
"""

import os
import re
import sys
from pathlib import Path
from typing import List, Dict, Set


def find_rails_root(start_path: str = ".") -> Path:
    """Find the Rails root directory"""
    current = Path(start_path).resolve()
    while current != current.parent:
        if (current / "config" / "application.rb").exists():
            return current
        current = current.parent
    raise FileNotFoundError("Could not find Rails root directory")


def parse_schema(schema_file: Path) -> Dict:
    """Parse the schema.rb file to extract tables, columns, and indexes"""
    with open(schema_file, 'r') as f:
        content = f.read()
    
    tables = {}
    current_table = None
    
    # Extract table definitions
    table_pattern = r'create_table\s+"(\w+)".*?do\s*\|t\|(.*?)end'
    for match in re.finditer(table_pattern, content, re.DOTALL):
        table_name = match.group(1)
        table_def = match.group(2)
        
        # Extract columns
        columns = []
        col_pattern = r't\.(\w+)\s+"(\w+)"'
        for col_match in re.finditer(col_pattern, table_def):
            columns.append(col_match.group(2))
        
        # Extract foreign keys
        foreign_keys = []
        fk_pattern = r't\.\w+\s+"(\w+_id)"'
        for fk_match in re.finditer(fk_pattern, table_def):
            foreign_keys.append(fk_match.group(1))
        
        tables[table_name] = {
            'columns': columns,
            'foreign_keys': foreign_keys,
            'indexes': []
        }
    
    # Extract index definitions
    index_pattern = r'add_index\s+"(\w+)",\s+\[?"(\w+)"?\]?'
    for match in re.finditer(index_pattern, content):
        table_name = match.group(1)
        column_name = match.group(2)
        if table_name in tables:
            tables[table_name]['indexes'].append(column_name)
    
    return tables


def analyze_missing_indexes(tables: Dict) -> List[Dict]:
    """Find foreign keys without indexes"""
    issues = []
    
    for table_name, table_info in tables.items():
        for fk in table_info['foreign_keys']:
            if fk not in table_info['indexes']:
                issues.append({
                    'table': table_name,
                    'column': fk,
                    'type': 'missing_foreign_key_index',
                    'severity': 'warning',
                    'message': f'Foreign key {fk} on {table_name} should have an index',
                    'suggestion': f'add_index :{table_name}, :{fk}'
                })
    
    return issues


def analyze_where_clauses(rails_root: Path) -> List[Dict]:
    """Analyze ActiveRecord queries for columns used in WHERE clauses"""
    issues = []
    seen_patterns = set()
    
    # Scan models and controllers for .where calls
    for pattern in ['app/models/**/*.rb', 'app/controllers/**/*.rb']:
        for file_path in rails_root.glob(pattern):
            try:
                with open(file_path, 'r') as f:
                    content = f.read()
                
                # Match .where(column: value) or .where("column = ?")
                where_patterns = [
                    r'\.where\(\s*(\w+):\s*',  # where(status: 'active')
                    r'\.where\(["\'](\w+)\s*=',  # where("status = ?")
                ]
                
                for pattern_re in where_patterns:
                    for match in re.finditer(pattern_re, content):
                        column = match.group(1)
                        pattern_key = f"{file_path.stem}:{column}"
                        if pattern_key not in seen_patterns:
                            seen_patterns.add(pattern_key)
                            issues.append({
                                'file': str(file_path),
                                'column': column,
                                'type': 'where_clause_column',
                                'severity': 'info',
                                'message': f'Column "{column}" used in WHERE clause - consider indexing if queries are slow'
                            })
            except Exception as e:
                pass
    
    return issues


def analyze_boolean_columns(tables: Dict) -> List[Dict]:
    """Identify boolean columns that might benefit from partial indexes"""
    issues = []
    
    for table_name, table_info in tables.items():
        for column in table_info['columns']:
            if column.startswith('is_') or column.startswith('has_') or column in ['active', 'enabled', 'published', 'deleted']:
                if column not in table_info['indexes']:
                    issues.append({
                        'table': table_name,
                        'column': column,
                        'type': 'boolean_index_opportunity',
                        'severity': 'info',
                        'message': f'Boolean column {column} on {table_name} might benefit from a partial index',
                        'suggestion': f'add_index :{table_name}, :{column}, where: "{column} = true"'
                    })
    
    return issues


def main():
    try:
        rails_root = find_rails_root()
    except FileNotFoundError:
        print("Error: Not in a Rails application directory", file=sys.stderr)
        sys.exit(1)
    
    schema_file = rails_root / "db" / "schema.rb"
    if not schema_file.exists():
        print("Error: Could not find db/schema.rb", file=sys.stderr)
        sys.exit(1)
    
    print(f"Analyzing database schema at: {rails_root}")
    print("=" * 80)
    
    # Parse schema
    tables = parse_schema(schema_file)
    print(f"Found {len(tables)} tables")
    
    # Run analyses
    missing_fk_indexes = analyze_missing_indexes(tables)
    where_clause_columns = analyze_where_clauses(rails_root)
    boolean_opportunities = analyze_boolean_columns(tables)
    
    all_issues = missing_fk_indexes + where_clause_columns + boolean_opportunities
    
    # Group by severity and type
    by_type = {}
    for issue in all_issues:
        issue_type = issue['type']
        if issue_type not in by_type:
            by_type[issue_type] = []
        by_type[issue_type].append(issue)
    
    # Print results
    print(f"\nFound {len(all_issues)} indexing opportunities:\n")
    
    # Missing foreign key indexes (high priority)
    if 'missing_foreign_key_index' in by_type:
        issues = by_type['missing_foreign_key_index']
        print(f"\n⚠️  MISSING FOREIGN KEY INDEXES ({len(issues)} issues):")
        print("-" * 80)
        for issue in issues:
            print(f"  Table: {issue['table']}, Column: {issue['column']}")
            print(f"  → {issue['message']}")
            print(f"  Migration: {issue['suggestion']}")
            print()
    
    # Boolean column opportunities
    if 'boolean_index_opportunity' in by_type:
        issues = by_type['boolean_index_opportunity']
        print(f"\nℹ️  BOOLEAN COLUMN INDEXING OPPORTUNITIES ({len(issues)} suggestions):")
        print("-" * 80)
        for issue in issues[:5]:  # Show first 5
            print(f"  Table: {issue['table']}, Column: {issue['column']}")
            print(f"  → {issue['message']}")
            print(f"  Migration: {issue['suggestion']}")
            print()
        if len(issues) > 5:
            print(f"  ... and {len(issues) - 5} more")
    
    # WHERE clause columns
    if 'where_clause_column' in by_type:
        issues = by_type['where_clause_column']
        print(f"\nℹ️  COLUMNS USED IN WHERE CLAUSES ({len(issues)} columns):")
        print("-" * 80)
        unique_columns = set(i['column'] for i in issues)
        print(f"  Consider adding indexes to these columns if queries are slow:")
        for col in sorted(unique_columns)[:10]:
            print(f"  • {col}")
        if len(unique_columns) > 10:
            print(f"  • ... and {len(unique_columns) - 10} more")
        print()
    
    if not all_issues:
        print("✓ No obvious indexing issues detected!")
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
