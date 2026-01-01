#!/usr/bin/env python3
"""
Analyze database.yml and suggest PostgreSQL configuration improvements.
Checks connection pool settings, timeouts, and common performance parameters.
"""

import os
import sys
import yaml
from pathlib import Path
from typing import Dict, List


def find_rails_root(start_path: str = ".") -> Path:
    """Find the Rails root directory"""
    current = Path(start_path).resolve()
    while current != current.parent:
        if (current / "config" / "application.rb").exists():
            return current
        current = current.parent
    raise FileNotFoundError("Could not find Rails root directory")


def load_database_config(config_file: Path) -> Dict:
    """Load and parse database.yml"""
    with open(config_file, 'r') as f:
        content = f.read()
        # Handle ERB tags by removing them (simplified)
        content = content.replace('<%=', '').replace('%>', '')
        return yaml.safe_load(content)


def analyze_connection_pool(env_config: Dict, env_name: str) -> List[Dict]:
    """Analyze connection pool configuration"""
    issues = []
    
    pool_size = env_config.get('pool')
    
    if pool_size is None:
        issues.append({
            'environment': env_name,
            'setting': 'pool',
            'severity': 'warning',
            'message': 'Connection pool size not explicitly set (defaults to 5)',
            'recommendation': 'Set pool size based on your application threads/workers. For Puma with 5 threads: pool: 5'
        })
    elif isinstance(pool_size, int):
        if pool_size < 5:
            issues.append({
                'environment': env_name,
                'setting': 'pool',
                'severity': 'warning',
                'message': f'Connection pool size ({pool_size}) is quite small',
                'recommendation': 'Consider increasing pool size to match your web server threads/workers'
            })
        elif pool_size > 20:
            issues.append({
                'environment': env_name,
                'setting': 'pool',
                'severity': 'info',
                'message': f'Connection pool size ({pool_size}) is quite large',
                'recommendation': 'Verify this matches your actual concurrency needs. Too many connections can strain PostgreSQL'
            })
    
    return issues


def analyze_timeouts(env_config: Dict, env_name: str) -> List[Dict]:
    """Analyze timeout configurations"""
    issues = []
    
    # Check statement timeout
    if 'variables' not in env_config or 'statement_timeout' not in env_config.get('variables', {}):
        issues.append({
            'environment': env_name,
            'setting': 'statement_timeout',
            'severity': 'warning',
            'message': 'statement_timeout not configured',
            'recommendation': '''Add to database.yml:
  variables:
    statement_timeout: 30000  # 30 seconds in milliseconds'''
        })
    
    # Check connect timeout
    if 'connect_timeout' not in env_config:
        issues.append({
            'environment': env_name,
            'setting': 'connect_timeout',
            'severity': 'info',
            'message': 'connect_timeout not configured',
            'recommendation': 'Add connect_timeout: 5 to prevent hanging on database connection issues'
        })
    
    # Check checkout timeout
    if 'checkout_timeout' not in env_config:
        issues.append({
            'environment': env_name,
            'setting': 'checkout_timeout',
            'severity': 'info',
            'message': 'checkout_timeout not configured (defaults to 5 seconds)',
            'recommendation': 'Explicitly set checkout_timeout: 5 for clarity'
        })
    
    return issues


def analyze_prepared_statements(env_config: Dict, env_name: str) -> List[Dict]:
    """Analyze prepared statements configuration"""
    issues = []
    
    prepared_statements = env_config.get('prepared_statements')
    
    if prepared_statements is False:
        issues.append({
            'environment': env_name,
            'setting': 'prepared_statements',
            'severity': 'info',
            'message': 'Prepared statements are disabled',
            'recommendation': 'Prepared statements improve performance. Only disable if using PgBouncer in transaction mode'
        })
    elif prepared_statements is None and env_name == 'production':
        issues.append({
            'environment': env_name,
            'setting': 'prepared_statements',
            'severity': 'info',
            'message': 'Prepared statements setting not explicit',
            'recommendation': 'Add prepared_statements: true for better query performance (enabled by default)'
        })
    
    return issues


def analyze_reaping_frequency(env_config: Dict, env_name: str) -> List[Dict]:
    """Analyze connection reaping configuration"""
    issues = []
    
    if 'reaping_frequency' not in env_config and env_name == 'production':
        issues.append({
            'environment': env_name,
            'setting': 'reaping_frequency',
            'severity': 'info',
            'message': 'reaping_frequency not configured',
            'recommendation': 'Consider adding reaping_frequency: 60 to clean up stale connections (seconds)'
        })
    
    return issues


def check_ssl_configuration(env_config: Dict, env_name: str) -> List[Dict]:
    """Check SSL/TLS configuration"""
    issues = []
    
    if env_name == 'production':
        sslmode = env_config.get('sslmode')
        if not sslmode or sslmode == 'disable':
            issues.append({
                'environment': env_name,
                'setting': 'sslmode',
                'severity': 'warning',
                'message': 'SSL/TLS not enforced for production database connections',
                'recommendation': 'Add sslmode: require or sslmode: verify-full for secure connections'
            })
    
    return issues


def suggest_performance_extensions(env_name: str) -> List[Dict]:
    """Suggest useful PostgreSQL extensions"""
    suggestions = []
    
    suggestions.append({
        'environment': env_name,
        'setting': 'extensions',
        'severity': 'info',
        'message': 'Consider enabling pg_stat_statements extension',
        'recommendation': '''Enable in PostgreSQL config:
  shared_preload_libraries = 'pg_stat_statements'
Then run: CREATE EXTENSION IF NOT EXISTS pg_stat_statements;'''
    })
    
    return suggestions


def main():
    try:
        rails_root = find_rails_root()
    except FileNotFoundError:
        print("Error: Not in a Rails application directory", file=sys.stderr)
        sys.exit(1)
    
    config_file = rails_root / "config" / "database.yml"
    if not config_file.exists():
        print("Error: Could not find config/database.yml", file=sys.stderr)
        sys.exit(1)
    
    print(f"Analyzing database configuration at: {rails_root}")
    print("=" * 80)
    
    try:
        config = load_database_config(config_file)
    except Exception as e:
        print(f"Error parsing database.yml: {e}", file=sys.stderr)
        sys.exit(1)
    
    all_issues = []
    
    # Analyze each environment
    for env_name in ['development', 'test', 'production']:
        if env_name not in config:
            continue
        
        env_config = config[env_name]
        if not isinstance(env_config, dict):
            continue
        
        issues = []
        issues.extend(analyze_connection_pool(env_config, env_name))
        issues.extend(analyze_timeouts(env_config, env_name))
        issues.extend(analyze_prepared_statements(env_config, env_name))
        issues.extend(analyze_reaping_frequency(env_config, env_name))
        issues.extend(check_ssl_configuration(env_config, env_name))
        
        all_issues.extend(issues)
    
    # Add extension suggestions
    all_issues.extend(suggest_performance_extensions('all'))
    
    # Group by severity
    by_severity = {'warning': [], 'info': []}
    for issue in all_issues:
        by_severity[issue['severity']].append(issue)
    
    # Print results
    print(f"\nFound {len(all_issues)} configuration recommendations:\n")
    
    for severity in ['warning', 'info']:
        issues = by_severity[severity]
        if issues:
            print(f"\n{severity.upper()} ({len(issues)} items):")
            print("-" * 80)
            for issue in issues:
                env = issue.get('environment', 'all')
                setting = issue.get('setting', 'general')
                print(f"  [{env}] {setting}")
                print(f"  → {issue['message']}")
                print(f"  💡 {issue['recommendation']}")
                print()
    
    if not all_issues:
        print("✓ Database configuration looks good!")
    else:
        print("\n" + "=" * 80)
        print("📚 For more information, see the High Performance PostgreSQL for Rails book")
        print("   Chapters: 2 (Administration Basics), 5 (Optimizing Active Record)")
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
