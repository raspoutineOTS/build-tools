#!/usr/bin/env python3
"""
Excel Data Extractor for WhatsApp attachments
Supports .xlsx, .xls, .csv
Extracts data, detects domains, and prepares for database storage
"""

import sys
import json
import os
from pathlib import Path
from datetime import datetime

# Configuration
OUTPUT_PATH = Path(os.getenv('EXCEL_OUTPUT_PATH', Path.home() / "processed-media" / "excel"))
OUTPUT_PATH.mkdir(parents=True, exist_ok=True)

def check_dependencies():
    """Check that Python dependencies are installed"""
    try:
        import openpyxl
        import pandas as pd
        return True, "openpyxl and pandas available"
    except ImportError as e:
        return False, f"Missing dependencies: {e}. Install with: pip install openpyxl pandas xlrd"

def extract_excel_data(file_path):
    """Extract data from an Excel file"""
    try:
        import pandas as pd

        file_ext = Path(file_path).suffix.lower()

        if file_ext == '.csv':
            df_dict = {'Sheet1': pd.read_csv(file_path)}
        elif file_ext in ['.xlsx', '.xls']:
            # Read all sheets
            excel_file = pd.ExcelFile(file_path)
            df_dict = {}

            for sheet_name in excel_file.sheet_names:
                df_dict[sheet_name] = pd.read_excel(file_path, sheet_name=sheet_name)
        else:
            return {
                'success': False,
                'error': f'Unsupported format: {file_ext}'
            }

        # Convert to JSON structures
        sheets_data = {}
        summary = {
            'total_sheets': len(df_dict),
            'total_rows': 0,
            'total_columns': 0,
            'sheets_summary': {}
        }

        for sheet_name, df in df_dict.items():
            # Clean NaN values
            df_clean = df.fillna('')

            sheets_data[sheet_name] = {
                'columns': df_clean.columns.tolist(),
                'rows_count': len(df_clean),
                'columns_count': len(df_clean.columns),
                'data': df_clean.to_dict('records')[:100],  # Limit to first 100 rows for preview
                'full_data_available': len(df_clean) > 100
            }

            summary['total_rows'] += len(df_clean)
            summary['total_columns'] += len(df_clean.columns)
            summary['sheets_summary'][sheet_name] = {
                'rows': len(df_clean),
                'columns': len(df_clean.columns),
                'column_names': df_clean.columns.tolist()
            }

        return {
            'success': True,
            'summary': summary,
            'sheets': sheets_data,
            'file_path': file_path,
            'file_size': os.path.getsize(file_path)
        }

    except Exception as e:
        return {
            'success': False,
            'error': str(e),
            'traceback': str(e.__traceback__)
        }

def detect_data_domains(excel_data, keywords_config=None):
    """
    Detect data domains in Excel data based on keywords
    Can be customized with your own keywords configuration
    """
    domains_detected = set()

    # Default keywords by domain (can be overridden)
    if keywords_config is None:
        keywords_config = {
            'medical': [
                'patient', 'hospital', 'medical', 'surgery', 'consultation',
                'doctor', 'nurse', 'treatment', 'diagnostic', 'pharmacy'
            ],
            'financial': [
                'budget', 'funding', 'finance', 'donor', 'invoice',
                'payment', 'expense', 'revenue', 'accounting'
            ],
            'logistics': [
                'transport', 'delivery', 'warehouse', 'vehicle',
                'fuel', 'stock', 'inventory', 'shipment'
            ],
            'hr': [
                'employee', 'staff', 'personnel', 'salary', 'payroll',
                'contract', 'recruitment', 'training'
            ]
        }

    # Analyze all sheets and cells
    for sheet_name, sheet_data in excel_data.get('sheets', {}).items():
        # Analyze column names
        columns = sheet_data.get('columns', [])
        for col in columns:
            col_lower = str(col).lower()
            for domain, domain_keywords in keywords_config.items():
                if any(kw in col_lower for kw in domain_keywords):
                    domains_detected.add(domain)

        # Analyze some data rows
        data_rows = sheet_data.get('data', [])
        for row in data_rows[:50]:  # Limit to first 50 rows
            row_text = ' '.join(str(v).lower() for v in row.values() if v)
            for domain, domain_keywords in keywords_config.items():
                if any(kw in row_text for kw in domain_keywords):
                    domains_detected.add(domain)

    return list(domains_detected)

def prepare_database_mapping(excel_data, domains, contact_name, message_id):
    """Prepare mapping for database storage"""

    db_mapping = {
        'data_schema': {
            'version': '1.0',
            'type': 'excel_document',
            'source': 'excel_extractor',
            'timestamp': datetime.now().isoformat(),
            'detected_domains': domains
        },
        'document_metadata': {
            'contact_name': contact_name,
            'message_id': message_id,
            'file_path': excel_data.get('file_path'),
            'file_size': excel_data.get('file_size'),
            'sheets_count': excel_data.get('summary', {}).get('total_sheets', 0),
            'total_rows': excel_data.get('summary', {}).get('total_rows', 0)
        },
        'domain_mappings': {},
        'excel_structure': excel_data.get('summary')
    }

    # Create mappings per domain
    for domain in domains:
        db_mapping['domain_mappings'][domain] = {
            'database': f'data_{domain}',
            'data_source': 'excel_file',
            'requires_analysis': True,
            'priority': 'medium'
        }

    return db_mapping

def save_extracted_data(contact_name, message_id, excel_data, domains, db_mapping):
    """Save extracted data"""
    timestamp = datetime.now().isoformat().replace(':', '-')

    # Save complete data
    output_file = OUTPUT_PATH / f"{contact_name}_{message_id}_{timestamp}.json"

    full_data = {
        'message_id': message_id,
        'contact_name': contact_name,
        'extraction_date': timestamp,
        'domains_detected': domains,
        'excel_data': excel_data,
        'database_mapping': db_mapping
    }

    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(full_data, f, indent=2, ensure_ascii=False)

    print(f"💾 Excel data saved: {output_file}")
    return str(output_file)

def process_excel_file(file_path, contact_name, message_id):
    """Process a complete Excel file"""
    print(f"\n{'='*60}")
    print(f"📊 PROCESSING EXCEL FILE")
    print(f"   File: {Path(file_path).name}")
    print(f"   Contact: {contact_name}")
    print(f"   Message ID: {message_id}")
    print(f"{'='*60}\n")

    # Check dependencies
    deps_ok, deps_msg = check_dependencies()
    if not deps_ok:
        print(f"❌ {deps_msg}")
        print("\n💡 Installation required:")
        print("   pip install openpyxl pandas xlrd")
        return {
            'success': False,
            'error': deps_msg
        }

    print(f"✅ {deps_msg}")

    # Extract data
    print("\n📈 Extracting data...")
    excel_data = extract_excel_data(file_path)

    if not excel_data.get('success'):
        print(f"❌ Extraction error: {excel_data.get('error')}")
        return excel_data

    summary = excel_data.get('summary', {})
    print(f"✅ Extraction successful:")
    print(f"   Sheets: {summary.get('total_sheets', 0)}")
    print(f"   Total rows: {summary.get('total_rows', 0)}")
    print(f"   Total columns: {summary.get('total_columns', 0)}")

    # Domain detection
    print("\n🔍 Detecting data domains...")
    domains = detect_data_domains(excel_data)
    print(f"✅ Domains detected: {', '.join(domains) if domains else 'None'}")

    # Prepare database mapping
    print("\n🗄️  Preparing database mapping...")
    db_mapping = prepare_database_mapping(excel_data, domains, contact_name, message_id)
    print(f"✅ Mapping created for {len(domains)} domains")

    # Save
    print("\n💾 Saving results...")
    saved_file = save_extracted_data(contact_name, message_id, excel_data, domains, db_mapping)

    print(f"\n{'='*60}")
    print(f"✅ PROCESSING COMPLETED")
    print(f"   Output file: {Path(saved_file).name}")
    print(f"   Domains: {', '.join(domains)}")
    print(f"{'='*60}\n")

    return {
        'success': True,
        'message_id': message_id,
        'contact_name': contact_name,
        'file_path': file_path,
        'domains': domains,
        'summary': summary,
        'saved_file': saved_file,
        'database_mapping': db_mapping
    }

def main():
    """Main entry point"""
    if len(sys.argv) < 4:
        print("Usage: excel-extractor.py <file_path> <contact_name> <message_id>")
        print("\nExample:")
        print("  python3 excel-extractor.py '/path/to/file.xlsx' 'Contact' 'MSG123'")
        sys.exit(1)

    file_path = sys.argv[1]
    contact_name = sys.argv[2]
    message_id = sys.argv[3]

    if not os.path.exists(file_path):
        print(f"❌ File not found: {file_path}")
        sys.exit(1)

    result = process_excel_file(file_path, contact_name, message_id)

    # Output JSON for integration
    print("\n" + json.dumps(result, ensure_ascii=False))

if __name__ == "__main__":
    main()
