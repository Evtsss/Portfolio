/* Финальный проект Яндекс Афиша
 *
 * Автор: Аргунова Ева
 * Дата:05.09.2026
*/



-- 1: Знакомство с данными
-- Объем таблиц
SELECT
    (SELECT COUNT(*) FROM afisha.purchases) AS purchases_count,
    (SELECT COUNT(*) FROM afisha.events) AS events_count,
    (SELECT COUNT(*) FROM afisha.venues) AS venues_count,
    (SELECT COUNT(*) FROM afisha.city) AS city_count,
    (SELECT COUNT(*) FROM afisha.regions) AS regions_count;


-- 1.2. Проверка уникальности идентификаторов 

SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT event_id) AS unique_event_id
FROM afisha.events;

SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT order_id) AS unique_order_id,
       COUNT(DISTINCT user_id) AS unique_user_id
FROM afisha.purchases;


-- 1.3. Проверка пропусков 

SELECT COUNT(*) AS total_rows,
	   COUNT(*) FILTER (WHERE order_id IS NULL) AS order_id_nulls,
       COUNT(*) FILTER (WHERE user_id IS NULL) AS user_id_nulls,
       COUNT(*) FILTER (WHERE created_dt_msk IS NULL) AS created_dt_msk_nulls,
       COUNT(*) FILTER (WHERE created_ts_msk IS NULL) AS created_ts_msk_nulls,
       COUNT(*) FILTER (WHERE event_id IS NULL) AS event_id_nulls,
       COUNT(*) FILTER (WHERE cinema_circuit IS NULL) AS cinema_circuit_nulls,
       COUNT(*) FILTER (WHERE age_limit IS NULL) AS age_limit_nulls,
       COUNT(*) FILTER (WHERE currency_code IS NULL) AS currency_code_nulls,
       COUNT(*) FILTER (WHERE device_type_canonical IS NULL) AS device_type_nulls,
       COUNT(*) FILTER (WHERE revenue IS NULL) AS revenue_nulls,
       COUNT(*) FILTER (WHERE service_name IS NULL) AS service_name_nulls,
       COUNT(*) FILTER (WHERE tickets_count IS NULL) AS tickets_count_nulls,
       COUNT(*) FILTER (WHERE total IS NULL) AS total_nulls
FROM afisha.purchases;

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE event_id IS NULL) AS event_id_nulls,
    COUNT(*) FILTER (WHERE event_name_code IS NULL) AS event_name_code_nulls,
    COUNT(*) FILTER (WHERE event_type_description IS NULL) AS event_type_description_nulls,
    COUNT(*) FILTER (WHERE event_type_main IS NULL) AS event_type_main_nulls,
    COUNT(*) FILTER (WHERE organizers IS NULL) AS organizers_nulls,
    COUNT(*) FILTER (WHERE city_id IS NULL) AS city_id_nulls,
    COUNT(*) FILTER (WHERE venue_id IS NULL) AS venue_id_nulls
FROM afisha.events;

-- 1.4. Дубликаты
SELECT
    order_id,
    COUNT(*) AS count  
FROM afisha.purchases
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY count DESC;


-- 1.5. Проверка категориальных значений 
-- Устройства
SELECT
    device_type_canonical,
    COUNT(*) AS orders_count
FROM afisha.purchases
GROUP BY device_type_canonical
ORDER BY orders_count DESC;

-- Валюты
SELECT
    currency_code,
    COUNT(*) AS orders_count
FROM afisha.purchases
GROUP BY currency_code
ORDER BY orders_count DESC;

-- Типы мероприятий по количеству заказов
SELECT
    e.event_type_main,
    COUNT(*) AS orders_count
FROM afisha.purchases p
JOIN afisha.events e
    ON p.event_id = e.event_id
GROUP BY e.event_type_main
ORDER BY orders_count DESC;

-- Возрастные ограничения
SELECT
    age_limit,
    COUNT(*) AS orders_count
FROM afisha.purchases
GROUP BY age_limit
ORDER BY age_limit;

-- 1.6. Период данных
SELECT
    MIN(created_dt_msk) AS min_date,
    MAX(created_dt_msk) AS max_date
FROM afisha.purchases;

-- 1.7. Проверка числовых показателей
SELECT
    tickets_count,
    COUNT(*) AS orders_count
FROM afisha.purchases
GROUP BY tickets_count
ORDER BY tickets_count;

SELECT
    order_id,
    tickets_count,
    total,
    revenue,
    currency_code
FROM afisha.purchases
LIMIT 20;

SELECT
    currency_code,
    COUNT(*) AS orders_count,
    MIN(revenue) AS min_revenue,
    MAX(revenue) AS max_revenue,
    ROUND(AVG(revenue)::numeric, 2) AS avg_revenue,
    ROUND(STDDEV(revenue)::numeric, 2) AS std_revenue
FROM afisha.purchases
GROUP BY currency_code
ORDER BY currency_code;

-- 1.8. Распределение заказов по операторам

SELECT
    service_name,
    COUNT(*) AS orders_count
FROM afisha.purchases
GROUP BY service_name
ORDER BY orders_count DESC;

-- 1.9. Проверка корректности данных операторов
SELECT DISTINCT
    service_name
FROM afisha.purchases
ORDER BY service_name;

-- 1.10. Количество уникальных событий, городов и регионов

SELECT
    COUNT(DISTINCT event_id) AS unique_events,
    COUNT(DISTINCT event_name_code) AS unique_event_names,
    COUNT(DISTINCT city_id) AS unique_cities
FROM afisha.events;

SELECT
    COUNT(DISTINCT region_id) AS unique_regions
FROM afisha.city;




