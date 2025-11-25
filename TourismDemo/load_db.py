#!/usr/bin/env python3
import pyodbc
import os

# Connection string
conn_str = 'Driver={ODBC Driver 17 for SQL Server};Server=DESKTOP-Q512LK2;Database=TourismDb;Trusted_Connection=yes;'

try:
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    
    # Read and execute schema script
    with open('DB_Schema_Full.sql', 'r', encoding='utf-8') as f:
        schema_script = f.read()
    
    # Split by GO and execute
    batches = schema_script.split('\nGO\n')
    for i, batch in enumerate(batches):
        batch = batch.strip()
        if batch:
            try:
                cursor.execute(batch)
                conn.commit()
                print(f"✅ Batch {i+1} executed successfully")
            except Exception as e:
                print(f"⚠️ Batch {i+1} error: {str(e)[:100]}")
                conn.rollback()
    
    print("\n📊 Schema script completed!")
    
    # Read and execute procedures script
    with open('DB_Procedures_Views_Triggers.sql', 'r', encoding='utf-8') as f:
        proc_script = f.read()
    
    batches = proc_script.split('\nGO\n')
    for i, batch in enumerate(batches):
        batch = batch.strip()
        if batch:
            try:
                cursor.execute(batch)
                conn.commit()
                print(f"✅ Proc Batch {i+1} executed successfully")
            except Exception as e:
                print(f"⚠️ Proc Batch {i+1} error: {str(e)[:100]}")
                conn.rollback()
    
    print("\n✅ All scripts loaded successfully!")
    cursor.close()
    conn.close()

except Exception as e:
    print(f"❌ Connection or execution error: {e}")
