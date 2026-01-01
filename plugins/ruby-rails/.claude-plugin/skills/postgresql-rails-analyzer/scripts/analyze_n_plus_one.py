#!/usr/bin/env python3
"""
Analyze Rails models and controllers for potential N+1 query issues.
Detects patterns where associations are accessed without eager loading.
"""

import os
import re
import sys
from pathlib import Path
from typing import List, Dict, Tuple


def find_rails_root(start_path: str = ".") -> Path:
    """Find the Rails root directory by looking for config/application.rb"""
    current = Path(start_path).resolve()
    while current != current.parent:
        if (current / "config" / "application.rb").exists():
            return current
        current = current.parent
    raise FileNotFoundError("Could not find Rails root directory")


def extract_associations(model_file: Path) -> Dict[str, List[str]]:
    """Extract associations (has_many, has_one, belongs_to) from a model file"""
    associations = {
        'has_many': [],
        'has_one': [],
        'belongs_to': []
    }
    
    with open(model_file, 'r') as f:
        content = f.read()
        
    # Match association declarations
    for assoc_type in associations.keys():
        pattern = rf'{assoc_type}\s+:(\w+)'
        matches = re.findall(pattern, content)
        associations[assoc_type].extend(matches)
    
    return associations


def analyze_controller_action(file_path: Path, content: str) -> List[Dict]:
    """Analyze controller action for potential N+1 queries"""
    issues = []
    lines = content.split('\n')
    
    for i, line in enumerate(lines, 1):
        # Look for queries without includes/preload/eager_load
        if re.search(r'\.(all|where|find_by|find)\b', line):
            # Check if there's no eager loading on this line or nearby lines
            context_start = max(0, i - 3)
            context_end = min(len(lines), i + 2)
            context = '\n'.join(lines[context_start:context_end])
            
            if not re.search(r'\.(includes|preload|eager_load)\b', context):
                # Check if the result is used with associations
                var_match = re.search(r'@(\w+)\s*=', line)
                if var_match:
                    var_name = var_match.group(1)
                    # Look ahead for usage of associations on this variable
                    for j in range(i, min(len(lines), i + 20)):
                        if re.search(rf'@{var_name}\.\w+\.\w+', lines[j]):
                            issues.append({
                                'file': str(file_path),
                                'line': i,
                                'type': 'potential_n_plus_one',
                                'severity': 'warning',
                                'message': f'Potential N+1 query: Query at line {i} may need eager loading'
                            })
                            break
    
    return issues


def analyze_view_file(file_path: Path, content: str) -> List[Dict]:
    """Analyze view file for association access patterns"""
    issues = []
    lines = content.split('\n')
    
    # Look for patterns like: object.association.each or object.association.attribute
    association_pattern = r'(\w+)\.(\w+)\.(each|map|size|count|\w+)'
    
    for i, line in enumerate(lines, 1):
        matches = re.findall(association_pattern, line)
        if matches:
            issues.append({
                'file': str(file_path),
                'line': i,
                'type': 'view_association_access',
                'severity': 'info',
                'message': f'Association access in view - verify eager loading in controller'
            })
    
    return issues


def scan_directory(directory: Path, file_pattern: str, analyzer_func) -> List[Dict]:
    """Scan directory for files matching pattern and analyze them"""
    all_issues = []
    
    for file_path in directory.rglob(file_pattern):
        try:
            with open(file_path, 'r') as f:
                content = f.read()
            issues = analyzer_func(file_path, content)
            all_issues.extend(issues)
        except Exception as e:
            print(f"Error analyzing {file_path}: {e}", file=sys.stderr)
    
    return all_issues


def main():
    try:
        rails_root = find_rails_root()
    except FileNotFoundError:
        print("Error: Not in a Rails application directory", file=sys.stderr)
        sys.exit(1)
    
    print(f"Analyzing Rails application at: {rails_root}")
    print("=" * 80)
    
    # Analyze controllers
    controllers_path = rails_root / "app" / "controllers"
    controller_issues = scan_directory(controllers_path, "*.rb", analyze_controller_action)
    
    # Analyze views
    views_path = rails_root / "app" / "views"
    view_issues = scan_directory(views_path, "*.erb", analyze_view_file)
    view_issues.extend(scan_directory(views_path, "*.haml", analyze_view_file))
    
    all_issues = controller_issues + view_issues
    
    # Group by severity
    by_severity = {'warning': [], 'info': []}
    for issue in all_issues:
        by_severity[issue['severity']].append(issue)
    
    # Print results
    print(f"\nFound {len(all_issues)} potential issues:\n")
    
    for severity in ['warning', 'info']:
        issues = by_severity[severity]
        if issues:
            print(f"\n{severity.upper()} ({len(issues)} issues):")
            print("-" * 80)
            for issue in issues:
                print(f"  {issue['file']}:{issue['line']}")
                print(f"  → {issue['message']}")
                print()
    
    if not all_issues:
        print("✓ No obvious N+1 query issues detected!")
    
    return 0 if not by_severity['warning'] else 1


if __name__ == "__main__":
    sys.exit(main())
