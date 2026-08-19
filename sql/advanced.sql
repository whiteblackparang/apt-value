USE apt_value;

-- 1. 구별 연도별 평당가 순위
SELECT
    gu_name, deal_year,
    ROUND(AVG(price_per_area), 1) AS avg_price,
    RANK() OVER (PARTITION BY deal_year ORDER BY AVG(price_per_area) DESC) AS gu_rank
FROM risk_scored
GROUP BY gu_name, deal_year
ORDER BY deal_year, gu_rank;

-- 2. 연도별 평당가 상승률 
WITH yearly_avg AS (
    SELECT deal_year, AVG(price_per_area) AS avg_price
    FROM risk_scored
    GROUP BY deal_year
)
SELECT
    deal_year,
    ROUND(avg_price, 1) AS avg_price,
    ROUND(100.0 * (avg_price - LAG(avg_price) OVER (ORDER BY deal_year)) / LAG(avg_price) OVER (ORDER BY deal_year), 1) AS yoy_growth_pct
FROM yearly_avg
ORDER BY deal_year;

-- 3. 구별 평당가 백분위 순위 
SELECT
    gu_name, price_per_area,
    ROUND(PERCENT_RANK() OVER (ORDER BY price_per_area), 3) AS price_percentile
FROM risk_scored
LIMIT 20;

-- 4. 연도별 거래건수 누적합 (running total)
WITH yearly_cnt AS (
    SELECT deal_year, COUNT(*) AS cnt
    FROM risk_scored
    GROUP BY deal_year
)
SELECT
    deal_year, cnt,
    SUM(cnt) OVER (ORDER BY deal_year) AS cumulative_cnt
FROM yearly_cnt
ORDER BY deal_year;

-- 5. 건축연한 구간별 평당가와 전체 평균의 차이
WITH age_avg AS (
    SELECT age, AVG(price_per_area) AS avg_price
    FROM risk_scored
    GROUP BY age
)
SELECT
    age, ROUND(avg_price, 1) AS avg_price,
    ROUND(avg_price - AVG(avg_price) OVER (), 1) AS diff_from_overall_avg
FROM age_avg
ORDER BY age;

-- 6. 거래별 괴리율 사분위
SELECT
    deal_year, deal_month, gap_ratio,
    NTILE(4) OVER (ORDER BY gap_ratio) AS gap_quartile
FROM risk_scored
LIMIT 20;

-- 7. 구별 최고가 거래 (파티션 내 1위)
SELECT gu_name, deal_year, deal_month, price_per_area
FROM (
    SELECT
        gu_name, deal_year, deal_month, price_per_area,
        ROW_NUMBER() OVER (PARTITION BY gu_name ORDER BY price_per_area DESC) AS rn
    FROM risk_scored
) ranked
WHERE rn = 1;

-- 8. 월별 이동평균 평당가 (3개월)
WITH monthly_avg AS (
    SELECT deal_year, deal_month, AVG(price_per_area) AS avg_price
    FROM risk_scored
    GROUP BY deal_year, deal_month
)
SELECT
    deal_year, deal_month, ROUND(avg_price, 1) AS avg_price,
    ROUND(AVG(avg_price) OVER (ORDER BY deal_year, deal_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 1) AS moving_avg_3m
FROM monthly_avg
ORDER BY deal_year, deal_month;

-- 9. 리스크 등급별 평당가와 등급 내 순위
SELECT
    risk_grade, price_per_area,
    RANK() OVER (PARTITION BY risk_grade ORDER BY price_per_area DESC) AS rank_in_grade
FROM risk_scored
LIMIT 20;

-- 10. 연도별 전년 대비 거래건수 증감
WITH yearly_cnt AS (
    SELECT deal_year, COUNT(*) AS cnt
    FROM risk_scored
    GROUP BY deal_year
)
SELECT
    deal_year, cnt,
    cnt - LAG(cnt) OVER (ORDER BY deal_year) AS yoy_diff
FROM yearly_cnt
ORDER BY deal_year;

-- 11. 구별 괴리율 중앙값에 가까운 거래 (근사)
SELECT gu_name, gap_ratio,
       ABS(gap_ratio - AVG(gap_ratio) OVER (PARTITION BY gu_name)) AS dist_from_avg
FROM risk_scored
ORDER BY gu_name, dist_from_avg
LIMIT 20;

-- 12. 건축연한별 거래 누적 비율
WITH age_cnt AS (
    SELECT age, COUNT(*) AS cnt
    FROM risk_scored
    GROUP BY age
)
SELECT
    age, cnt,
    ROUND(100.0 * SUM(cnt) OVER (ORDER BY age) / SUM(cnt) OVER (), 1) AS cumulative_pct
FROM age_cnt
ORDER BY age;

-- 13. 전용면적 상위 10% 거래의 평균 괴리율
WITH ranked AS (
    SELECT excluUseAr, gap_ratio,
           PERCENT_RANK() OVER (ORDER BY excluUseAr) AS pr
    FROM risk_scored
)
SELECT ROUND(AVG(gap_ratio), 2) AS avg_gap_top10pct_area
FROM ranked
WHERE pr >= 0.9;

-- 14. 구별·연도별 평당가 3개년 이동평균
WITH gu_year_avg AS (
    SELECT gu_name, deal_year, AVG(price_per_area) AS avg_price
    FROM risk_scored
    GROUP BY gu_name, deal_year
)
SELECT
    gu_name, deal_year, ROUND(avg_price, 1) AS avg_price,
    ROUND(AVG(avg_price) OVER (PARTITION BY gu_name ORDER BY deal_year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 1) AS moving_avg_3y
FROM gu_year_avg
ORDER BY gu_name, deal_year;

-- 15. 층수별 평당가 순위와 전체 대비 백분위
SELECT
    floor, ROUND(AVG(price_per_area), 1) AS avg_price,
    ROUND(PERCENT_RANK() OVER (ORDER BY AVG(price_per_area)), 3) AS floor_price_percentile
FROM risk_scored
GROUP BY floor
ORDER BY floor;

-- 16. 리스크 등급별 거래 비중 변화 (연도별)
SELECT
    deal_year, risk_grade,
    COUNT(*) AS cnt,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY deal_year), 1) AS pct_within_year
FROM risk_scored
GROUP BY deal_year, risk_grade
ORDER BY deal_year, pct_within_year DESC;

-- 17. 예측 오차 상위 5% 거래 추출
WITH error_ranked AS (
    SELECT *,
           ABS(price_per_area - predicted_price_per_area) AS abs_error,
           PERCENT_RANK() OVER (ORDER BY ABS(price_per_area - predicted_price_per_area)) AS pr
    FROM risk_scored
)
SELECT deal_year, deal_month, gu_name, abs_error
FROM error_ranked
WHERE pr >= 0.95
ORDER BY abs_error DESC;

-- 18. 구간별(건축연한) 평당가 최고/최저 거래 
SELECT DISTINCT
    age,
    FIRST_VALUE(price_per_area) OVER (PARTITION BY age ORDER BY price_per_area DESC) AS max_price_in_age,
    FIRST_VALUE(price_per_area) OVER (PARTITION BY age ORDER BY price_per_area ASC) AS min_price_in_age
FROM risk_scored
ORDER BY age
LIMIT 20;

-- 19. 연도별 리스크 등급 구성비 변화 추적 
WITH yearly_grade AS (
    SELECT deal_year, risk_grade, COUNT(*) AS cnt
    FROM risk_scored
    GROUP BY deal_year, risk_grade
)
SELECT
    deal_year, risk_grade, cnt,
    cnt - LAG(cnt) OVER (PARTITION BY risk_grade ORDER BY deal_year) AS yoy_change
FROM yearly_grade
ORDER BY risk_grade, deal_year;

-- 20. 구별 평당가 표준화 점수 
SELECT
    gu_name, price_per_area,
    ROUND((price_per_area - AVG(price_per_area) OVER (PARTITION BY gu_name)) /
          STDDEV(price_per_area) OVER (PARTITION BY gu_name), 2) AS z_score
FROM risk_scored
LIMIT 20;