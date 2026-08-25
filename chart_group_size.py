"""
chart_group_size.py — Bieu do dau tien cua ban

Tra loi cau hoi: di bao nhieu nguoi thi taxi bat dau dang tien?

Chay:
    pip3 install pandas matplotlib
    python3 chart_group_size.py

Ket qua: file group_size_comparison.png trong cung thu muc.
"""

import sqlite3
import pandas as pd
import matplotlib.pyplot as plt


# ---------------------------------------------------------------
# BUOC 1 — Doc du lieu tu database vao DataFrame
# ---------------------------------------------------------------
# DataFrame la "bang tinh trong Python": co cot, co dong, co ten cot.
# Neu ban hinh dung duoc sheet Excel thi ban hinh dung duoc DataFrame.

con = sqlite3.connect("metravel.db")

df = pd.read_sql_query("""
    SELECT city, method_name, price_basis, price_min_vnd
    FROM routes
""", con)

con.close()

print("Doc duoc", len(df), "dong")
print(df.head())          # .head() = xem 5 dong dau, giong nhin luot bang Excel
print()


# ---------------------------------------------------------------
# BUOC 2 — Tach hai nhom: tinh theo nguoi va tinh theo xe
# ---------------------------------------------------------------
# Dong duoi doc la: "lay nhung dong ma cot price_basis bang 'per_person'".
# Dau ngoac vuong [] trong pandas = "loc".

theo_nguoi = df[df["price_basis"] == "per_person"]
theo_xe    = df[df["price_basis"] == "per_vehicle"]

# .groupby("city")["cot"].min() = "gom theo thanh pho, lay gia nho nhat cua cot do"
# Y het GROUP BY trong SQL ban da viet.
re_nhat_cong_cong = theo_nguoi.groupby("city")["price_min_vnd"].min()
re_nhat_xe_rieng  = theo_xe.groupby("city")["price_min_vnd"].min()

print("Cong cong re nhat moi thanh pho:")
print(re_nhat_cong_cong)
print()


# ---------------------------------------------------------------
# BUOC 3 — Tinh chi phi moi nguoi khi di 1, 2, 3, 4 nguoi
# ---------------------------------------------------------------
# Cong cong: moi nguoi mua mot ve -> chi phi khong doi.
# Xe rieng: chia deu cho so nguoi.

so_nguoi = [1, 2, 3, 4]
cac_thanh_pho = sorted(re_nhat_cong_cong.index)

ket_qua = {}
for tp in cac_thanh_pho:
    ket_qua[tp] = {
        "cong_cong": [re_nhat_cong_cong[tp]] * 4,
        "xe_rieng":  [re_nhat_xe_rieng[tp] / n for n in so_nguoi],
    }


# ---------------------------------------------------------------
# BUOC 4 — Ve bieu do
# ---------------------------------------------------------------
# subplots(1, 3) = mot hang, ba o ve canh nhau (moi thanh pho mot o).
# figsize tinh bang inch.

fig, cac_o = plt.subplots(1, 3, figsize=(13, 4.5), sharey=True)

for o, tp in zip(cac_o, cac_thanh_pho):
    d = ket_qua[tp]

    o.plot(so_nguoi, d["cong_cong"], marker="o", linewidth=2,
           label="Cong cong (re nhat)", color="#2E7D5B")
    o.plot(so_nguoi, d["xe_rieng"], marker="s", linewidth=2,
           label="Xe rieng (chia deu)", color="#C1543A")

    o.set_title(tp, fontsize=12, fontweight="bold")
    o.set_xlabel("So nguoi di cung")
    o.set_xticks(so_nguoi)
    o.grid(alpha=0.25)

    # Ghi con so cu the o diem 1 nguoi va 4 nguoi
    for i in (0, 3):
        o.annotate(f"{int(d['xe_rieng'][i]):,}",
                   (so_nguoi[i], d["xe_rieng"][i]),
                   textcoords="offset points", xytext=(0, 9),
                   ha="center", fontsize=8, color="#C1543A")

cac_o[0].set_ylabel("Chi phi MOI NGUOI (VND)")
cac_o[0].legend(fontsize=9)

fig.suptitle(
    "Di cang dong, khoang cach giua xe rieng va cong cong cang thu hep",
    fontsize=13, fontweight="bold", y=1.02)

plt.tight_layout()
plt.savefig("group_size_comparison.png", dpi=150, bbox_inches="tight")
print("Da luu group_size_comparison.png")


# ---------------------------------------------------------------
# BUOC 5 — In ra ket luan bang chu
# ---------------------------------------------------------------
print()
print("Ty le xe rieng / cong cong:")
for tp in cac_thanh_pho:
    d = ket_qua[tp]
    gap1 = d["xe_rieng"][0] / d["cong_cong"][0]
    gap4 = d["xe_rieng"][3] / d["cong_cong"][3]
    print(f"  {tp:12} 1 nguoi: {gap1:5.1f} lan   |   4 nguoi: {gap4:4.1f} lan")
