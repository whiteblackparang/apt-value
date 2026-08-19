USE apt_value;

-- 1. Critical 등급 거래 중 괴리율 상위 10건
SELECT deal_year, deal_month, price_per_area, predicted_price_per_area, gap_ratio
FROM risk_scored
WHERE risk_grade = 'Critical (고평가 위험)'
ORDER BY gap_ratio ASC
LIMIT 10;

-- 2. 구별 리스크 등급 분포
SELECT
    CASE WHEN gu_name_seocho = 1 THEN 'seocho' ELSE 'gangnam' END AS gu_name,
    SUM(CASE WHEN risk_grade = 'Critical (고평가 위험)' THEN 1 ELSE 0 END) AS critical_cnt,
    SUM(CASE WHEN risk_grade = 'High' THEN 1 ELSE 0 END) AS high_cnt,
    SUM(CASE WHEN risk_grade = 'Moderate' THEN 1 ELSE 0 END) AS moderate_cnt,
    COUNT(*) AS total_cnt
FROM risk_scored
GROUP BY gu_name_seocho;

-- 3. 평균 대비 20% 이상 벗어난 거래 비율 (연도별)
SELECT
    deal_year,
    ROUND(100.0 * SUM(CASE WHEN ABS(gap_ratio) >= 20 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_extreme
FROM risk_scored
GROUP BY deal_year
ORDER BY deal_year;

-- 4. 전체 평균보다 비싼 거래만 조회
SELECT
    deal_year,
    CASE WHEN gu_name_seocho = 1 THEN 'seocho' ELSE 'gangnam' END AS gu_name,
    price_per_area
FROM risk_scored
WHERE price_per_area > (SELECT AVG(price_per_area) FROM risk_scored)
ORDER BY price_per_area DESC
LIMIT 20;

-- 5. 구별 평균 평당가가 전체 평균을 넘는 구만 조회
SELECT
    CASE WHEN gu_name_seocho = 1 THEN 'seocho' ELSE 'gangnam' END AS gu_name,
    ROUND(AVG(price_per_area), 1) AS avg_price
FROM risk_scored
GROUP BY gu_name_seocho
HAVING AVG(price_per_area) > (SELECT AVG(price_per_area) FROM risk_scored);

-- 6. 건축연한 구간별 평당가
SELECT
    CASE
        WHEN age < 10 THEN '10년 미만'
        WHEN age < 20 THEN '10-20년'
        WHEN age < 30 THEN '20-30년'
        WHEN age < 40 THEN '30-40년'
        ELSE '40년 이상'
    END AS age_group,
    ROUND(AVG(price_per_area), 1) AS avg_price
FROM risk_scored
GROUP BY age_group;

-- 7. 리스크 등급별 평균 전용면적
SELECT risk_grade, ROUND(AVG(excluUseAr), 1) AS avg_area
FROM risk_scored
GROUP BY risk_grade
ORDER BY avg_area DESC;

-- 8. 분양권 여부에 따른 평당가 비교
SELECT
    CASE WHEN is_presale = 1 THEN '분양권' ELSE '완공' END AS deal_type,
    ROUND(AVG(price_per_area), 1) AS avg_price,
    COUNT(*) AS cnt
FROM risk_scored
GROUP BY deal_type;

-- 9. 월별 거래 건수가 가장 많은 달
SELECT deal_month, COUNT(*) AS cnt
FROM risk_scored
GROUP BY deal_month
HAVING COUNT(*) = (
    SELECT MAX(month_cnt) FROM (
        SELECT COUNT(*) AS month_cnt FROM risk_scored GROUP BY deal_month
    ) AS sub
);

-- 10. 재건축 후보 여부에 따른 평당가·괴리율 비교
SELECT
    CASE WHEN is_reconstruction_candidate = 1 THEN '재건축후보' ELSE '일반' END AS building_type,
    ROUND(AVG(price_per_area), 1) AS avg_price,
    ROUND(AVG(gap_ratio), 2) AS avg_gap
FROM risk_scored
GROUP BY building_type;

-- 11. 층수 구간별 리스크 등급 분포
SELECT
    CASE
        WHEN floor <= 5 THEN '저층'
        WHEN floor <= 15 THEN '중층'
        ELSE '고층'
    END AS floor_group,
    risk_grade,
    COUNT(*) AS cnt
FROM risk_scored
GROUP BY floor_group, risk_grade
ORDER BY floor_group, cnt DESC;

-- 12. 구별 Critical 비율
SELECT
    CASE WHEN gu_name_seocho = 1 THEN 'seocho' ELSE 'gangnam' END AS gu_name,
    ROUND(100.0 * SUM(CASE WHEN risk_grade = 'Critical (고평가 위험)' THEN 1 ELSE 0 END) / COUNT(*), 2) AS critical_pct
FROM risk_scored
GROUP BY gu_name_seocho;

-- 13. 연도별 평균 평당가
SELECT deal_year, ROUND(AVG(price_per_area), 1) AS avg_price
FROM risk_scored
GROUP BY deal_year
ORDER BY deal_year;

-- 14. 예측 오차(절댓값)가 큰 상위 20건
SELECT deal_year, deal_month, price_per_area, predicted_price_per_area,
       ROUND(ABS(price_per_area - predicted_price_per_area), 1) AS abs_error
FROM risk_scored
ORDER BY abs_error DESC
LIMIT 20;

-- 15. 평형대별 리스크 등급 분포
SELECT
    CASE
        WHEN excluUseAr < 40 THEN '소형'
        WHEN excluUseAr < 60 THEN '국민평형'
        WHEN excluUseAr < 85 THEN '중형'
        WHEN excluUseAr < 135 THEN '대형'
        ELSE '초대형'
    END AS area_group,
    risk_grade,
    COUNT(*) AS cnt
FROM risk_scored
GROUP BY area_group, risk_grade
ORDER BY area_group, cnt DESC;

-- 16. 전체 평균보다 예측 오차가 큰 거래 비율
SELECT
    ROUND(100.0 * SUM(CASE WHEN ABS(price_per_area - predicted_price_per_area) >
        (SELECT AVG(ABS(price_per_area - predicted_price_per_area)) FROM risk_scored)
        THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_above_avg_error
FROM risk_scored;

-- 17. 구·연도별 거래 건수
SELECT
    CASE WHEN gu_name_seocho = 1 THEN 'seocho' ELSE 'gangnam' END AS gu_name,
    deal_year, COUNT(*) AS cnt
FROM risk_scored
GROUP BY gu_name_seocho, deal_year
ORDER BY deal_year, gu_name;

-- 18. 저평가(Very Low) 등급 중 대형 평형(85㎡ 이상) 비율
SELECT
    ROUND(100.0 * SUM(CASE WHEN excluUseAr >= 85 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_large_area
FROM risk_scored
WHERE risk_grade = 'Very Low (저평가)';

-- 19. 월별 평균 괴리율이 가장 큰 달
SELECT deal_month, ROUND(AVG(gap_ratio), 2) AS avg_gap
FROM risk_scored
GROUP BY deal_month
ORDER BY avg_gap DESC
LIMIT 1;

-- 20. 건축연한 40년 이상 & Critical/High 등급
SELECT
    deal_year, deal_month, age,
    CASE WHEN gu_name_seocho = 1 THEN 'seocho' ELSE 'gangnam' END AS gu_name,
    risk_grade
FROM risk_scored
WHERE age >= 40 AND risk_grade IN ('Critical (고평가 위험)', 'High')
ORDER BY age DESC;