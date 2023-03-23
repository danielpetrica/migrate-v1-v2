-- account
INSERT INTO "user"
(user_id, username, password, role, created_at, updated_at, deleted_at)
SELECT account_uuid,
    username,
    password,
    CASE WHEN is_admin = true THEN 'admin' ELSE 'user' END,
    created_at,
    updated_at,
    NULL
FROM v1_account
WHERE NOT EXISTS (SELECT 1 FROM "user");

-- website
INSERT INTO website
(website_id, name, domain, share_id, rev_id, user_id, team_id, created_at)
SELECT website_uuid,
    name,
    domain,
    share_id,
    0 rev_id,
    a.account_uuid,
    NULL team_id,
    a.created_at
FROM v1_website w
JOIN v1_account a
ON a.user_id = w.user_id
WHERE NOT EXISTS (SELECT 1 FROM website);

-- session
INSERT INTO session
(session_id, website_id, hostname, browser, os, device, screen, language, country)
SELECT session_uuid,
    w.website_uuid,
    hostname,
    browser,
    os,
    device,
    screen,
    language,
    country
FROM v1_session s
JOIN v1_website w
ON w.website_id = s.website_id
WHERE NOT EXISTS (SELECT 1 FROM session);

-- pageview
INSERT INTO website_event
(event_id, website_id, session_id, created_at, url_path, url_query, referrer_path, referrer_query, referrer_domain, event_type)
SELECT gen_random_uuid() event_id,
    w.website_uuid,
    s.session_uuid,
    p.created_at,
    CASE
        WHEN position('?' in url) > 0 THEN substring(url, 0, position('?' in url))
        ELSE url
    END url_path,
    CASE
        WHEN position('?' in url) > 0 THEN substring(url, position('?' in url) + 1)
        ELSE ''
    END url_query
    p.referrer,
    1 event_type
FROM v1_pageview p
JOIN v1_session s
ON s.session_id = p.session_id
JOIN v1_website w
ON w.website_id = s.website_id
WHERE NOT EXISTS (SELECT 1 FROM website_event WHERE event_type = 1);

-- event / event_data
INSERT INTO website_event
(event_id, website_id, session_id, created_at, url_path, url_query, event_type, event_name)
SELECT e.event_uuid,
    w.website_uuid,
    s.session_uuid,
    e.created_at,
    CASE
        WHEN position('?' in url) > 0 THEN substring(url, 0, position('?' in url))
        ELSE url
    END url_path,
    CASE
        WHEN position('?' in url) > 0 THEN substring(url, position('?' in url) + 1)
        ELSE ''
    END url_query
    2 event_type,
    e.event_name,
    ed.event_data
FROM v1_event e
JOIN v1_session s
ON s.session_id = e.session_id
JOIN v1_website w
ON w.website_id = s.website_id
WHERE NOT EXISTS (SELECT 1 FROM website_event WHERE event_type = 2);