-- =====================================================
-- Проект: Анализ данных сервиса Яндекс Книги
-- Период данных: 01.09.2024 – 11.12.2024
-- =====================================================


-- =====================================================
-- 1. MAU авторов
-- Задача: определить топ-3 авторов по количеству
-- уникальных пользователей за ноябрь 2024 года.
-- =====================================================

SELECT
    a.main_author_name,
    COUNT(DISTINCT au.puid) AS mau
FROM bookmate.audition AS au
JOIN bookmate.content AS c
    ON au.main_content_id = c.main_content_id
JOIN bookmate.author AS a
    ON c.main_author_id = a.main_author_id
WHERE au.msk_business_dt_str >= '2024-11-01'
  AND au.msk_business_dt_str < '2024-12-01'
GROUP BY a.main_author_name
ORDER BY mau DESC
LIMIT 3;


-- =====================================================
-- 2. MAU произведений
-- Задача: определить топ-3 произведения по количеству
-- уникальных пользователей за ноябрь 2024 года.
-- Дополнительно вывести жанр и автора произведения.
-- =====================================================

SELECT
    c.main_content_name,
    c.published_topic_title_list,
    a.main_author_name,
    COUNT(DISTINCT au.puid) AS mau
FROM bookmate.audition AS au
JOIN bookmate.content AS c
    ON au.main_content_id = c.main_content_id
JOIN bookmate.author AS a
    ON c.main_author_id = a.main_author_id
WHERE au.msk_business_dt_str >= '2024-11-01'
  AND au.msk_business_dt_str < '2024-12-01'
GROUP BY
    c.main_content_name,
    c.published_topic_title_list,
    a.main_author_name
ORDER BY mau DESC
LIMIT 3;


-- =====================================================
-- 3. Retention Rate
-- Задача: рассчитать ежедневное удержание пользователей,
-- которые были активны 2 декабря 2024 года.
-- =====================================================

-- Формируем когорту пользователей, активных 2 декабря.
WITH cohort AS (
    SELECT DISTINCT puid
    FROM bookmate.audition
    WHERE msk_business_dt_str = '2024-12-02'
),

-- Получаем даты активности пользователей этой когорты.
activity AS (
    SELECT DISTINCT
        a.puid,
        a.msk_business_dt_str::date AS activity_date
    FROM bookmate.audition AS a
    INNER JOIN cohort AS c
        ON a.puid = c.puid
    WHERE a.msk_business_dt_str::date >= '2024-12-02'
),

-- Считаем количество вернувшихся пользователей
-- для каждого дня после даты формирования когорты.
retention AS (
    SELECT
        activity_date - '2024-12-02'::date AS day_since_install,
        COUNT(DISTINCT puid) AS retained_users
    FROM activity
    GROUP BY activity_date - '2024-12-02'::date
)

SELECT
    day_since_install,
    retained_users,

    -- Делим число активных пользователей за день
    -- на размер когорты.
    ROUND(
        retained_users::numeric / MAX(retained_users) OVER (),
        2
    ) AS retention_rate
FROM retention
ORDER BY day_since_install;


-- =====================================================
-- 4. LTV пользователей по городам
-- Задача: рассчитать средний LTV пользователей Москвы
-- и Санкт-Петербурга.
-- Стоимость месячной подписки — 399 рублей.
-- Каждый месяц активности пользователя учитывается
-- как оплата одной подписки.
-- =====================================================

-- Получаем уникальные сочетания пользователя,
-- города и месяца активности.
WITH user_months AS (
    SELECT DISTINCT
        a.puid,
        g.usage_geo_id_name AS city,
        DATE_TRUNC('month', a.msk_business_dt_str::date) AS month
    FROM bookmate.audition AS a
    JOIN bookmate.geo AS g
        ON a.usage_geo_id = g.usage_geo_id
    WHERE g.usage_geo_id_name IN ('Москва', 'Санкт-Петербург')
),

-- Считаем количество пользователей и выручку
-- по каждому городу.
city_ltv AS (
    SELECT
        city,
        COUNT(DISTINCT puid) AS total_users,
        COUNT(*) * 399 AS total_revenue
    FROM user_months
    GROUP BY city
)

SELECT
    city,
    total_users,
    ROUND(total_revenue::numeric / total_users, 2) AS ltv
FROM city_ltv
ORDER BY ltv DESC;


-- =====================================================
-- 5. Средняя выручка за час прослушивания
-- Задача: рассчитать MAU, общее количество часов
-- прослушивания и среднюю выручку за час
-- с сентября по ноябрь 2024 года.
-- Стоимость месячной подписки — 399 рублей.
-- =====================================================

-- Считаем месячную аудиторию и общее время прослушивания.
WITH monthly_metrics AS (
    SELECT
        DATE_TRUNC('month', msk_business_dt_str::date)::date AS month,
        COUNT(DISTINCT puid) AS mau,
        SUM(hours) AS hours
    FROM bookmate.audition
    WHERE msk_business_dt_str::date >= '2024-09-01'
      AND msk_business_dt_str::date < '2024-12-01'
    GROUP BY DATE_TRUNC('month', msk_business_dt_str::date)::date
)

SELECT
    month,
    mau,
    ROUND(hours::numeric, 2) AS hours,
    ROUND((mau * 399.0) / hours, 2) AS avg_hour_rev
FROM monthly_metrics
ORDER BY month;


-- =====================================================
-- 6. Подготовка данных для проверки гипотезы
-- Задача: получить суммарное время прослушивания
-- каждого пользователя из Москвы и Санкт-Петербурга.
-- Результат используется для дальнейшего анализа
-- в Python и сравнения двух групп.
-- =====================================================

SELECT
    usage_geo_id_name AS city,
    puid,
    SUM(hours) AS hours
FROM bookmate.audition
JOIN bookmate.geo USING (usage_geo_id)
WHERE usage_geo_id_name IN ('Москва', 'Санкт-Петербург')
GROUP BY
    usage_geo_id_name,
    puid;