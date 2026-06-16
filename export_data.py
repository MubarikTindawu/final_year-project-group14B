import firebase_admin
import matplotlib.pyplot as plt
from firebase_admin import credentials, firestore
import pandas as pd
from datetime import datetime
import os

# 1. Initialize Firebase
# Make sure "serviceAccountKey.json" is in the same folder as this script
if not firebase_admin._apps:
    try:
        cred = credentials.Certificate("serviceAccountKey.json")
        firebase_admin.initialize_app(cred)
    except Exception as e:
        print(f"❌ Error loading Service Account Key: {e}")
        exit()

db = firestore.client()
date_str = datetime.now().strftime("%Y_%m_%d")

# 2. Define the collections we want to audit
categories = ["crops", "inventory", "transactions"]

print(f"🚀 Starting Master Farm Audit for {date_str}...")
print("-" * 50)

for category in categories:
    print(f"Checking '{category}' across all users...")

    # Using collection_group to find this folder inside ANY user document
    docs = db.collection_group(category).stream()

    data_list = []
    for doc in docs:
        data = doc.to_dict()

        # --- SAFE PATH CHECKING ---
        # doc.reference.parent is the collection (e.g., 'crops')
        # doc.reference.parent.parent is the user document
        ref_path = doc.reference.parent.parent

        if ref_path:
            data['owner_id'] = ref_path.id
        else:
            # This happens if the collection is at the root level, not inside a user
            data['owner_id'] = "ROOT_LEVEL"

        data['doc_id'] = doc.id
        data_list.append(data)

    # 3. Save each category to its own CSV file
    if data_list:
        df = pd.DataFrame(data_list)
        filename = f"farm_{category}_{date_str}.csv"
        df.to_csv(filename, index=False)
        print(f"✅ Success! Saved {len(data_list)} records to {filename}")

        # --- CROP SPECIFIC ANALYSIS & CHARTING ---
        if category == "crops":
            # Calculate Total Acreage for your report
            if 'area' in df.columns:
                total_area = df['area'].sum()
                print(f"📊 Total Managed Area: {total_area:.2f} Acres")

            # Generate Pie Chart if 'name' exists
            if 'name' in df.columns:
                plt.figure(figsize=(10, 7))
                df['name'].value_counts().plot(
                    kind='pie',
                    autopct='%1.1f%%',
                    startangle=140,
                    colors=['#4CAF50', '#8BC34A', '#CDDC39', '#FFEB3B', '#FFC107']
                )
                plt.title(f"Crop Distribution Audit - {date_str}")
                plt.ylabel('') # Hides the vertical label

                chart_name = f"crop_distribution_{date_str}.png"
                plt.savefig(chart_name)
                plt.close() # Free up memory
                print(f"📈 Chart generated: {chart_name}")

    else:
        print(f"ℹ️  No data found for '{category}'.")

    print("-" * 50)

print("\n📂 Audit Complete. Check your project folder for the new CSV and PNG files!")