.headers on
.mode column

-- MeTravel — Phân tích dữ liệu vận chuyển sân bay
-- Bộ dữ liệu: 8 tuyến Bangkok (BKK + DMK), thu thập 2026-08

-- =========================================================
-- Q2. "Giá của sự tiện lợi" — đi phương tiện công cộng rẻ nhất
--     so với đi taxi/xe riêng thì chênh bao nhiêu lần?
-- =========================================================
WITH public_cheapest AS (
    SELECT origin, MIN(price_min_vnd) AS public_min
    FROM routes
    WHERE method_type IN ('train', 'bus', 'metro')
      AND price_min_vnd IS NOT NULL
    GROUP BY origin
),
private_dearest AS (
    SELECT origin, MAX(price_max_vnd) AS private_max
    FROM routes
    WHERE method_type IN ('taxi', 'ride_hail', 'private_car')
      AND price_max_vnd IS NOT NULL
    GROUP BY origin
)
SELECT
    p.origin,
    p.public_min                                   AS re_nhat_vnd,
    d.private_max                                  AS dat_nhat_vnd,
    ROUND(CAST(d.private_max AS REAL) / p.public_min, 1) AS gap_bao_nhieu_lan
FROM public_cheapest p
JOIN private_dearest d ON p.origin = d.origin
ORDER BY gap_bao_nhieu_lan DESC;


-- =========================================================
-- Q3. Hạ cánh nửa đêm thì còn lựa chọn nào?
--     Lọc các tuyến còn hoạt động sau 24:00.
-- =========================================================
SELECT
    route_id,
    method_name,
    operates_from || ' - ' || operates_to AS gio_chay,
    price_min_vnd,
    price_max_vnd,
    CASE WHEN operates_to = '24:00' AND operates_from = '00:00'
         THEN 'Chay 24/7'
         ELSE 'DONG CUA ban dem' END AS trang_thai_dem
FROM routes
WHERE origin LIKE 'Suvarnabhumi%'
ORDER BY price_min_vnd;


-- =========================================================
-- Q4. Có liên hệ giữa độ khó ngôn ngữ và biên độ giá không?
--     (Không biết tiếng bản địa có phải là một khoản thuế?)
-- =========================================================
SELECT
    language_difficulty_1_5 AS do_kho_ngon_ngu,
    COUNT(*)                AS so_tuyen,
    ROUND(AVG(CAST(price_max_local AS REAL) / price_min_local), 2) AS bien_do_gia_tb
FROM routes
WHERE language_difficulty_1_5 IS NOT NULL
  AND price_min_local IS NOT NULL
  AND price_min_local > 0
GROUP BY language_difficulty_1_5
ORDER BY do_kho_ngon_ngu;


-- =========================================================
-- Q5. Ngân sách di chuyển thực tế cho 1 chuyến khứ hồi sân bay,
--     theo 3 phong cách du lịch.
-- =========================================================
SELECT
    CASE
        WHEN comfort_1_5 <= 2 THEN '1. Tiet kiem'
        WHEN comfort_1_5 = 3  THEN '2. Can bang'
        ELSE                       '3. Thoai mai'
    END AS phong_cach,
    COUNT(*)                     AS so_lua_chon,
    MIN(price_min_vnd) * 2       AS khu_hoi_thap_nhat,
    MAX(price_max_vnd) * 2       AS khu_hoi_cao_nhat
FROM routes
WHERE comfort_1_5 IS NOT NULL AND price_min_vnd IS NOT NULL
GROUP BY phong_cach
ORDER BY phong_cach;


-- =========================================================
-- Kiểm tra chất lượng dữ liệu — chạy sau mỗi lần thêm dòng
-- =========================================================
SELECT
    'Thieu gia'            AS van_de, COUNT(*) AS so_dong FROM routes WHERE price_min_local IS NULL
UNION ALL SELECT 'Thieu comfort',      COUNT(*) FROM routes WHERE comfort_1_5 IS NULL
UNION ALL SELECT 'Thieu do kho ngon ngu', COUNT(*) FROM routes WHERE language_difficulty_1_5 IS NULL
UNION ALL SELECT 'Thieu last_updated', COUNT(*) FROM routes WHERE last_updated IS NULL
UNION ALL SELECT 'luggage_ok sai chuan', COUNT(*) FROM routes
    WHERE luggage_ok IS NOT NULL AND luggage_ok NOT IN ('yes','tight','no');


-- =========================================================
-- Q6. Nhóm bao nhiêu người thì đi taxi rẻ hơn đi tàu?
--     (Chỉ trả lời được sau khi có cột price_basis)
-- =========================================================
WITH re_nhat AS (
    SELECT city, MIN(price_min_vnd) AS cong_cong
    FROM routes WHERE price_basis = 'per_person' GROUP BY city
),
xe_rieng AS (
    SELECT city, method_name, MIN(price_min_vnd) AS ca_xe
    FROM routes WHERE price_basis = 'per_vehicle' GROUP BY city
)
SELECT
    x.city,
    x.method_name                              AS xe_re_nhat,
    CAST(r.cong_cong AS INT)                   AS cong_cong_moi_nguoi,
    CAST(x.ca_xe     AS INT)                   AS xe_rieng_1_nguoi,
    CAST(x.ca_xe / 2 AS INT)                   AS xe_rieng_2_nguoi,
    CAST(x.ca_xe / 4 AS INT)                   AS xe_rieng_4_nguoi,
    ROUND(x.ca_xe * 1.0 / r.cong_cong, 1)      AS gap_1_nguoi,
    ROUND(x.ca_xe / 4.0 / r.cong_cong, 1)      AS gap_4_nguoi
FROM xe_rieng x JOIN re_nhat r ON x.city = r.city
ORDER BY gap_1_nguoi DESC;


-- =========================================================
-- Q7. So sánh chéo 3 thành phố — thành phố nào "thân thiện"
--     nhất với người hạ cánh muộn và không biết tiếng?
-- =========================================================
SELECT
    city,
    COUNT(*)                                                        AS so_phuong_an,
    SUM(CASE WHEN operates_to = '24:00' AND operates_from = '00:00'
             THEN 1 ELSE 0 END)                                     AS so_phuong_an_24_7,
    ROUND(AVG(language_difficulty_1_5), 1)                          AS do_kho_ngon_ngu_tb,
    ROUND(AVG(comfort_1_5), 1)                                      AS tien_nghi_tb,
    CAST(MIN(price_min_vnd) AS INT)                                 AS re_nhat_vnd
FROM routes
GROUP BY city
ORDER BY do_kho_ngon_ngu_tb;
