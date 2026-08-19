USE apt_value;

-- 1. 구별 평균 평당가
SELECT
    CASE WHEN gu_name_seocho = 1 THEN 'seocho' ELSE 'gangnam' END AS gu_name,
    ROUND(AVG(price_per_area), 1) AS avg_price_per_area
FROM risk_scored
GROUP BY gu_name_seocho;

-- 2. 연도별 거래 건수
SELECT deal_year, COUNT(*) AS deal_count
FROM risk_scored
GROUP BY deal_year
ORDER BY deal_year;

-- 3. 리스크 등급별 건수
SELECT risk_grade, COUNT(*) AS cnt
FROM risk_scored
GROUP BY risk_grade
ORDER BY cnt DESC;

-- 4. 층수별 평균 괴리율
SELECT floor, ROUND(AVG(gap_ratio), 2) AS avg_gap
FROM risk_scored
GROUP BY floor
ORDER BY floor;

-- 5. 전체 평당가 통계
SELECT
    MIN(price_per_area) AS min_price,
    MAX(price_per_area) AS max_price,
    ROUND(AVG(price_per_area), 1) AS avg_price,
    ROUND(STDDEV(price_per_area), 1) AS std_price
FROM risk_scored;

-- 6. 월별 거래 건수
SELECT deal_month, COUNT(*) AS deal_count
FROM risk_scored
GROUP BY deal_month
ORDER BY deal_month;

-- 7. Critical 등급 거래만 조회
SELECT *
FROM risk_scored
WHERE risk_grade = 'Critical (고평가 위험)'
LIMIT 20;

-- 8. 전용면적 80㎡ 이상 거래
SELECT deal_year, deal_month, excluUseAr, price_per_area
FROM risk_scored
WHERE excluUseAr >= 80
ORDER BY price_per_area DESC
LIMIT 20;

-- 9. 건축연한 30년 이상 거래 건수
SELECT COUNT(*) AS old_building_count
FROM risk_scored
WHERE age >= 30;

-- 10. 분양권 거래 건수
SELECT COUNT(*) AS presale_count
FROM risk_scored
WHERE is_presale = 1;

-- 11. 재건축 후보 거래 건수
SELECT COUNT(*) AS reconstruction_candidate_count
FROM risk_scored
WHERE is_reconstruction_candidate = 1;

-- 12. 평당가 상위 20건
SELECT
    deal_year, deal_month,
    CASE WHEN gu_name_seocho = 1 THEN 'seocho' ELSE 'gangnam' END AS gu_name,
    price_per_area
FROM risk_scored
ORDER BY price_per_area DESC
LIMIT 20;

-- 13. 평당가 하위 20건
SELECT
    deal_year, deal_month,
    CASE WHEN gu_name_seocho = 1 THEN 'seocho' ELSE 'gangnam' END AS gu_name,
    price_per_area
FROM risk_scored
ORDER BY price_per_area ASC
LIMIT 20;

-- 14. 2025년 거래만 필터
SELECT deal_month, COUNT(*) AS cnt
FROM risk_scored
WHERE deal_year = 2025
GROUP BY deal_month
ORDER BY deal_month;

-- 15. 예측 평당가와 실거래 평당가 평균 비교
SELECT
    ROUND(AVG(price_per_area), 1) AS avg_actual,
    ROUND(AVG(predicted_price_per_area), 1) AS avg_predicted
FROM risk_scored;

-- 16. 괴리율 절댓값 상위 20건
SELECT deal_year, deal_month, price_per_area, predicted_price_per_area, gap_ratio
FROM risk_scored
ORDER BY ABS(gap_ratio) DESC
LIMIT 20;

-- 17. 층수 1~5층(저층) 거래 건수
SELECT COUNT(*) AS low_floor_count
FROM risk_scored
WHERE floor BETWEEN 1 AND 5;

-- 18. 건축연한별 거래 건수 분포
SELECT age, COUNT(*) AS cnt
FROM risk_scored
GROUP BY age
ORDER BY age;

-- 19. 괴리율이 양수인 거래 비율
SELECT
    ROUND(100.0 * SUM(CASE WHEN gap_ratio > 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_positive_gap
FROM risk_scored;

-- 20. 구별 거래 건수
SELECT
    CASE WHEN gu_name_seocho = 1 THEN 'seocho' ELSE 'gangnam' END AS gu_name,
    COUNT(*) AS cnt
FROM risk_scored
GROUP BY gu_name_seocho;