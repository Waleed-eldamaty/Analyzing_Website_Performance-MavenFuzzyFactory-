-- Main Objective (1): Identifying Top Website Pages

-- Task: An Email was sent on June 09-2012 from the Website Manager: Morgan Rockwell and it includes the following:

-- I’m Morgan, the new Website Manager. Could you help me get my head around the site by pulling the most viewed website pages, ranked by session volume
-- -----------------------------------------------------------------------------------------------------------------------------

-- Soultion Starts:

SELECT
pageview_url,
count(distinct website_session_id) AS PageViews
FROM website_pageviews
WHERE created_at < '2012-06-09'
GROUP BY 1
Order BY 2 DESC;

-- Conclusion to Objective (1):
-- The Home page, Products Page and The original mr fuzzy page have the most number of page views.

-- -----------------------------------------------------------------------------------------------------------------------------

-- Main Objective (2): Identifying Top Entry Pages

-- Task: An Email was sent on June 12-2012 from the Website Manager: Morgan Rockwell and it includes the following:

-- Would you be able to pull a list of the top entry pages ? I want to confirm where our users are hitting the site.
-- If you could pull all entry pages and rank them on entry volume , that would be great
-- -----------------------------------------------------------------------------------------------------------------------------
-- Solution Starts:

-- To solve this we are going to do the following:
-- STEP 1: Find the first pageview_id for each given website_session_id then saving it in a temporary table
-- STEP 2: Find the url the customer saw on that first pageview by joining the original table and the temporary table together

CREATE TEMPORARY TABLE First_PageView_id_per_Session
Select
website_session_id,
MIN(website_pageview_id) AS First_PageView_id -- To choose the first landing page/pageview_id in each session since the (website_pageview_id) is auto incrementing
FROM website_pageviews
WHERE created_at < '2012-06-12'
GROUP BY website_session_id;

SELECT
First_PageView_id_per_Session.website_session_id,
website_pageviews.pageview_url AS Landing_Page_URL
FROM First_PageView_id_per_Session
LEFT JOIN website_pageviews
ON website_pageviews.website_pageview_id=First_PageView_id_per_Session.First_PageView_id;

-- For a better Solution do the following:
SELECT
website_pageviews.pageview_url AS Landing_Page_URL,
COUNT( First_PageView_id_per_Session.website_session_id) AS Sessions_Hitting_This_Landing_Page
FROM First_PageView_id_per_Session
LEFT JOIN website_pageviews
ON website_pageviews.website_pageview_id=First_PageView_id_per_Session.First_PageView_id 
Group BY website_pageviews.pageview_url;

-- Conclusion to Objective (2):
-- All of the traffic is coming through the home page. Thus, the main focus should be on it for the time being.

-- -----------------------------------------------------------------------------------------------------------------------------

-- Main Objective (3): Calculating Bounce Rates

-- Task: An Email was sent on June 14-2012 from the Website Manager: Morgan Rockwell and it includes the following:

-- The other day you showed us that all of our traffic is landing on the homepage right now. We should check how that landing page is performing.
-- Can you pull bounce rates for traffic landing on the homepage? I would like to see three numbers… Sessions , Bounced Sessions , and % of Sessions which Bounced (aka “Bounce Rate")

-- To solve this we are going to do the following:
-- STEP 1: Find the first pageview_id for each given website_session_id then saving it in a temporary table
-- STEP 2: Find the url the customer saw on that first pageview by joining the original table and the temporary table together. then save it in a new temporary table
-- STEP 3: Counting Pageviews for each session to identify "Bounced Sessions"
-- STEP 4: Summarizing by Counting Total Sessions and Bounced Sessions
-- -----------------------------------------------------------------------------------------------------------------------------
-- Solution Starts:

-- STEP 1: Find the first pageview_id for each given website_session_id then saving it in a temporary table

CREATE TEMPORARY TABLE First_PageView_id_per_Session_2
 -- Created a new temp table (Table 1 = First_PageView_id_per_Session_2) to identify the first pageview ID for each session
Select
website_session_id,
MIN(website_pageview_id) AS First_PageView_id -- To choose the first landing page/pageview_id in each session since the (website_pageview_id) is auto incrementing
FROM website_pageviews
WHERE created_at < '2012-06-14'
GROUP BY website_session_id;

-- FOR QA 
SELECT*FROM First_PageView_id_per_Session_2;

-- -----------------------------------------------------------------------------------------------------------------------------

-- STEP 2: Find the url the customer saw on that first pageview by joining the original table and the temporary table together. then save it in a new temporary table

CREATE TEMPORARY TABLE Sessions_With_Home_As_Landing_Page 
-- Created a new temp table (Table 2 = Sessions_With_Home_As_Landing_Page) to identify the first pageview  URL (Landing Page) for each session
-- By Left Joining Table 1 (Created in STEP 1) & the original website pageviews (To call the URL from it) Through Website Page View ID
SELECT
First_PageView_id_per_Session_2.website_session_id,
website_pageviews.pageview_url AS Landing_Page_URL
FROM First_PageView_id_per_Session_2
LEFT JOIN website_pageviews
ON website_pageviews.website_pageview_id=First_PageView_id_per_Session_2.First_PageView_id -- One to One (Unique to Unique)
WHERE website_pageviews.pageview_url='/home'; -- Since from the previous analysis/task,  All of the traffic is coming through the home page.

-- FOR QA 
SELECT*FROM Sessions_With_Home_As_Landing_Page;

-- -----------------------------------------------------------------------------------------------------------------------------

-- STEP 3: Counting Pageviews for eachs session to identify "Bounces"

CREATE TEMPORARY TABLE Bounced_Sessions
-- Created a new temp table (Table 3 = Bounced_Sessions) to identify the bounced sessions ID (sessions where Customers left after landing on the 1st page)
-- By Left Joining Table 2 (Created in STEP 2) & the original website pageviews (To call the website_session_id from it) Through Website Session ID 
SELECT
Sessions_With_Home_As_Landing_Page.website_session_id,
Sessions_With_Home_As_Landing_Page.Landing_Page_URL,
count(website_pageviews.website_session_id) AS Count_of_pages_Viewed -- Count the number of pages visited
FROM Sessions_With_Home_As_Landing_Page
LEFT JOIN website_pageviews
ON website_pageviews.website_session_id=Sessions_With_Home_As_Landing_Page.website_session_id -- One To Many ( Sessions_With_Home_As_Landing_Page.website_session_id TO website_pageviews.website_session_id)
GROUP BY 
Sessions_With_Home_As_Landing_Page.website_session_id,
Sessions_With_Home_As_Landing_Page.Landing_Page_URL
HAVING Count_of_pages_Viewed = 1; -- To limit the sessions_id to the ones where customers landed only on the home page then left/bounced

-- FOR QA 
SELECT*FROM Bounced_Sessions;

-- -----------------------------------------------------------------------------------------------------------------------------

-- STEP 4: Summarizing by Counting Total Sessions and Bounced Sessions
-- We Left Joined Table 2 (To call the total sessions) & Table 3 (To call the bounced sessions) Through Website Session ID

SELECT
Sessions_With_Home_As_Landing_Page.website_session_id,
Bounced_Sessions.website_session_id AS Bounced_Website_session_id
FROM Sessions_With_Home_As_Landing_Page -- The First Table is Sessions_With_Home_As_Landing_Page beaucse we want all of its results(Total Sessions)
LEFT JOIN Bounced_Sessions -- The Second Table is Bounced_Sessions beaucse we only want results that match the first table
ON Sessions_With_Home_As_Landing_Page.website_session_id=Bounced_Sessions.website_session_id -- One to One (Unique to Unique)
ORDER BY Sessions_With_Home_As_Landing_Page.website_session_id;

-- The Null values of this Query indicate that this website session was not a boucned session (Customer kept going after the initial landing on the initial home page)

-- To count the Sessions, same as previous query but add COUNT:
SELECT
COUNT(DISTINCT Sessions_With_Home_As_Landing_Page.website_session_id) AS Number_of_Sessions,
COUNT(DISTINCT Bounced_Sessions.website_session_id) AS Number_of_Bounced_Sessions,
COUNT(DISTINCT Bounced_Sessions.website_session_id)/COUNT(DISTINCT Sessions_With_Home_As_Landing_Page.website_session_id) AS Bounce_Rate
FROM Sessions_With_Home_As_Landing_Page -- The First Table is Sessions_With_Home_As_Landing_Page beaucse we want all of its results(Total Sessions)
LEFT JOIN Bounced_Sessions -- The Second Table is Bounced_Sessions beaucse we only want results that match the first table
ON Sessions_With_Home_As_Landing_Page.website_session_id=Bounced_Sessions.website_session_id; -- One to One (Unique to Unique)

-- Conclusion to Objective (3):
-- The Bounce rate is very high almost 60% specially for paid traffic.
-- A new landing page could be desinged, tested, compared to the original home page and then evalute its performance

-- -----------------------------------------------------------------------------------------------------------------------------

-- Main Objective (4): Analyzing Landing Page Tests

-- Task: An Email was sent on July 28-2012 from the Website Manager: Morgan Rockwell and it includes the following:

-- Based on your bounce rate analysis, we ran a new custom landing page ( (/lander 1 ) in a 50/50 test against the homepage ((/home for our gsearch nonbrand traffic).
-- Can you pull bounce rates for the two groups so we can evaluate the new page? Make sure to just look at the time period where /lander 1 was getting traffic , so that it is a fair comparison.

-- To solve this we are going to do the following:
-- STEP 0: Find when was the new page (/lander 1) launched to be used as a criteria
-- STEP 1: Find the first website pageview ID for the relevant sessions to be used as a criteria
-- STEP 2: Identify the landing page of each session
-- STEP 3: Coutning Page Views for each session to identify "Bounces"
-- STEP 4: Summarizing by Counting Total Sessions and Bounced Sessions, by LP
-- -----------------------------------------------------------------------------------------------------------------------------
-- Solution Starts:

-- STEP 0: Find when was the new page (/lander 1) launched (To use in STEP 2 to limit the results for the timer period where /lander 1 was getting traffic , so that it is a fair comparison)

SELECT
pageview_url,
MIN(created_at)
FROM website_pageviews
WHERE pageview_url = '/lander-1'
GROUP BY 1;

-- The Result of the previous query showed that:
-- The first time the '/lander-1' Page was Created_At= '2012-06-19 00:35:54'

-- -----------------------------------------------------------------------------------------------------------------------------

-- STEP 1: Find the first website pageview ID for the new custom page (/lander-1) (To use in STEP 2 to limit the result for the time period where /lander 1 was getting traffic , so that it is a fair comparison)

SELECT
pageview_url,
MIN(created_at) AS First_Created_At,
MIN(website_pageview_id) AS First_PageView_id
FROM website_pageviews
WHERE pageview_url = '/lander-1';

-- The Result of the previous query showed that:
-- The first time the '/lander-1' Page was Created_At= '2012-06-19 00:35:54' & First_PageView_ID= '23504'
-- Hence, Either one of them can be used to limit the results as mentioned before, but we will choose the Pageview ID as it is more accurate for the analysis than just the date

-- -----------------------------------------------------------------------------------------------------------------------------

-- STEP 2: A) Find the website session ID and minimum pageview ID that match the filtering criteria

CREATE TEMPORARY TABLE First_Test_PageViews_2
SELECT
website_pageviews.website_session_id,
MIN(website_pageviews.website_pageview_id) AS Min_Pageview_id
-- website_session_id [Could be used in the SELECT statement if no other column from different table was needed - gsearch & nonbrand]
-- MIN(website_pageview_id) [Could be used in the SELECT statement if no other column from different table was needed - gsearch & nonbrand]
FROM website_pageviews
INNER JOIN website_sessions -- Joined with Website_Sessions because the analysis is requested for gsearch & nonbrand as well which are only available in website_sessions table
ON website_sessions.website_session_id= website_pageviews.website_session_id -- One to Many
WHERE website_pageviews.created_at < '2012-07-28' -- As per the email
AND  website_pageview_id >'23504'  -- Or it could be as follows: BETWEEN  '2012-06-19' AND '2012-07-28'
AND utm_source ='gsearch'
AND utm_campaign= 'nonbrand'
GROUP BY website_pageviews.website_session_id;

-- The result of the previous query showed the list of Website Sessions ID that matched the following criteria:
-- was created after website_pageview_id= '23504' & website_pageviews.created_at < '2012-07-28' & utm_source ='gsearch' AND utm_campaign= 'nonbrand'

-- FOR QA
SELECT*FROM First_Test_PageViews_2;

-- STEP 2: B) Identify the landing page of the relevant sessions shown in Part A of STEP 2

CREATE TEMPORARY TABLE nonbrand_test_sessions_with_landing_page
SELECT
First_Test_PageViews_2.website_session_id, -- brings the website session_id that match the previously mentioned criteria
website_pageviews.pageview_url AS Landing_Page -- brings the corresponding URL for each website session
FROM First_Test_PageViews_2
LEFT JOIN website_pageviews
ON First_Test_PageViews_2.Min_Pageview_id=website_pageviews.website_pageview_id -- One to One (Unique to Unique)
WHERE website_pageviews.pageview_url IN ('/home' , '/lander-1'); -- Limit the results to '/home' & '/lander-1' only

-- The result of the previous query showed the Full list of (TOTAL NUMBER = Bounce + Unbounced) Website Sessions ID that matched the following criteria:
-- was created after website_pageview_id= '23504' & website_pageviews.created_at < '2012-07-28' & utm_source ='gsearch' AND utm_campaign= 'nonbrand'
-- AND its corresponding URL/Landing Page

-- FOR QA
SELECT*FROM nonbrand_test_sessions_with_landing_page;

-- -----------------------------------------------------------------------------------------------------------------------------

-- STEP 3: Coutning Page Views for each session to identify "Bounces"

CREATE TEMPORARY TABLE nonbrand_test_bounced_sessions
SELECT
nonbrand_test_sessions_with_landing_page.website_session_id,
nonbrand_test_sessions_with_landing_page.Landing_Page,
COUNT(website_pageviews.website_pageview_id) As Counts_of_PageView
FROM nonbrand_test_sessions_with_landing_page
LEFT JOIN website_pageviews
ON nonbrand_test_sessions_with_landing_page.website_session_id =website_pageviews.website_session_id -- One to Many
GROUP BY
nonbrand_test_sessions_with_landing_page.website_session_id,
nonbrand_test_sessions_with_landing_page.Landing_Page
HAVING COUNT(website_pageviews.website_pageview_id) = 1; -- To limit the results to the "Bounced" Sessions only

-- The result of the query showed the same list shown before in STEP 2 but was limited (part of TOTAL NUMBER= Bounced) to only website session id who had only 1 pageview count (Bounced)

-- FOR QA
SELECT*FROM nonbrand_test_bounced_sessions;

-- -----------------------------------------------------------------------------------------------------------------------------

-- STEP 4: Summarizing by Counting Total Sessions and Bounced Sessions, By LP

SELECT
nonbrand_test_sessions_with_landing_page.Landing_Page,
nonbrand_test_sessions_with_landing_page.website_session_id,
nonbrand_test_bounced_sessions.website_session_id AS Bounced_Website_Session_id
FROM nonbrand_test_sessions_with_landing_page
LEFT JOIN nonbrand_test_bounced_sessions
ON nonbrand_test_sessions_with_landing_page.website_session_id=nonbrand_test_bounced_sessions.website_session_id -- One to One
ORDER BY
nonbrand_test_sessions_with_landing_page.website_session_id;

-- The result of the previous query showed which website session was bounced and which was not (Showed Null)


-- To count and calculate the bounce rate, the following query was written:
SELECT
nonbrand_test_sessions_with_landing_page.Landing_Page,
COUNT(nonbrand_test_sessions_with_landing_page.website_session_id) AS Number_of_Website_Sessions,
COUNT(nonbrand_test_bounced_sessions.website_session_id) AS Number_of_Bounced_Website_Session_id,
COUNT(nonbrand_test_bounced_sessions.website_session_id)/ COUNT(nonbrand_test_sessions_with_landing_page.website_session_id) AS Bounce_Rate
FROM nonbrand_test_sessions_with_landing_page
LEFT JOIN nonbrand_test_bounced_sessions
ON nonbrand_test_sessions_with_landing_page.website_session_id=nonbrand_test_bounced_sessions.website_session_id -- One to One
GROUP BY
nonbrand_test_sessions_with_landing_page.Landing_Page;

-- Conclusion to Objective (4):
-- The Bounce rate of the new custom page (/lander-1) was lower than the original page (/home)
--  nonbrand paid Campagins should be updated to focus on the new custom page
-- -----------------------------------------------------------------------------------------------------------------------------

-- Main Objective (5): Landing Page Trend Analysis

-- Task: An Email was sent on August 31-2012 from the Website Manager: Morgan Rockwell and it includes the following:

-- Could you pull the volume of paid search nonbrand traffic landing on /home and /lander 1, trended weekly since June 1st? I want to confirm the traffic is all routed correctly.
-- Could you also pull our overall paid search bounce rate trended weekly ? I want to make sure the lander change has improved the overall picture.

-- To solve this we are going to do the following:
-- STEP 1: Find the first website pageview ID for the relevant sessions to be used as a criteria
-- STEP 2: Identify the landing page of each session
-- STEP 3: Coutning Page Views for each session to identify "Bounces"
-- STEP 4: Summarizing by Counting Total Sessions and Bounced Sessions, By WEEK
-- -----------------------------------------------------------------------------------------------------------------------------

-- Solution Starts:

-- STEP 1: Find the first website pageview ID for the relevant sessions

CREATE TEMPORARY TABLE Sessions_With_Min_PageView_ID_AND_View_Count

SELECT
website_sessions.website_session_id,
MIN(website_pageviews.website_pageview_id) AS First_PageView_id, -- Usually used for Joining Tables
COUNT(website_pageviews.website_pageview_id) AS count_pageviews
FROM website_sessions
LEFT JOIN website_pageviews
ON website_sessions.website_session_id=website_pageviews.website_session_id
WHERE website_sessions.created_at >'2012-06-01' AND website_sessions.created_at < '2012-08-31'
AND website_sessions.utm_source = 'gsearch'
AND website_sessions.utm_campaign='nonbrand'
group by website_sessions.website_session_id;


-- For QA
SELECT*FROM Sessions_With_Min_PageView_ID_AND_View_Count;

-- -----------------------------------------------------------------------------------------------------------------------------

-- STEP 2: Identify the landing page of each session obtained from STEP 1

CREATE TEMPORARY TABLE Sessions_With_counts_lander_and_created_at_2
SELECT
Sessions_With_Min_PageView_ID_AND_View_Count.website_session_id, -- Coulmn Created in STEP 1
Sessions_With_Min_PageView_ID_AND_View_Count.First_PageView_id, -- Coulmn Created in STEP 1
Sessions_With_Min_PageView_ID_AND_View_Count.count_pageviews, -- Coulmn Created in STEP 1
website_pageviews.pageview_url AS Landing_Page,
website_pageviews.created_at AS Session_Created_At -- To use it in the next step for weekly trends
FROM Sessions_With_Min_PageView_ID_AND_View_Count
LEFT JOIN website_pageviews
ON Sessions_With_Min_PageView_ID_AND_View_Count.First_PageView_id=website_pageviews.website_pageview_id;

-- For QA
SELECT*FROM Sessions_With_counts_lander_and_created_at_2;
-- -----------------------------------------------------------------------------------------------------------------------------


-- STEP 3 & 4 Together: Coutning Page Views for each session to identify "Bounces" & Summarizing by Counting Total Sessions and Bounced Sessions, By WEEK

SELECT
YEARWEEK (Session_Created_At) AS Year_Week, -- Not really Needed
min(date(Session_Created_At)) AS Week_Start_Date,
COUNT(DISTINCT website_session_id) AS Total_Sessions,
COUNT(DISTINCT CASE WHEN count_pageviews = 1 THEN website_session_id ELSE NULL END) AS Bounced_Sessions,
COUNT(DISTINCT CASE WHEN count_pageviews = 1 THEN website_session_id ELSE NULL END) / COUNT(distinct website_session_id) AS Bounce_Rate,
COUNT(DISTINCT CASE WHEN Landing_page = '/home' THEN website_session_id ELSE NULL END) AS Home_Sessions,
COUNT(DISTINCT CASE WHEN Landing_page = '/lander-1' THEN website_session_id ELSE NULL END) AS lander_Sessions
FROM Sessions_With_counts_lander_and_created_at_2
GROUP BY YEARWEEK (Session_Created_At);

-- Conclusion to Objective (5):
-- Both pages were getting hits untill we fully switched on the custom lander page
-- Moreover, the overall bounce rate has decreased

-- -----------------------------------------------------------------------------------------------------------------------------

-- Main Objective (6): Building Conversion Funnels

-- Task: An Email was sent on September 05-2012 from the Website Manager: Morgan Rockwell and it includes the following:

-- I’d like to understand where we lose our gsearch visitors between the new /lander 1 page and placing an order.
-- Can you build us a full conversion funnel, analyzing how many customers make it to each step
-- Start with /lander 1 and build the funnel all the way to our thank you page . Please use data since August 5 th

-- To solve this we are going to do the following:
-- STEP 1: Select all pageviews for relevant sessions
-- STEP 2: Identify each pageview as the specfic funnel step
-- STEP 3: Create Session-Level conversion funnel view
-- STEP 4: Aggregate the data to asses the funnel performance
-- -----------------------------------------------------------------------------------------------------------------------------

-- Soultion Starts:

-- STEP 1: Select all pageviews for relevant sessions & STEP 2: Identify each pageview as the specfic funnel step

-- Creating Flags
SELECT
website_sessions.website_session_id,
website_pageviews.pageview_url,
CASE WHEN pageview_url='/products' THEN 1 ELSE 0 END AS Products_Page, -- Creating flags for each page
CASE WHEN pageview_url='/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS Mr_Fuzzy_Page, -- Creating flags for each page
CASE WHEN pageview_url='/cart' THEN 1 ELSE 0 END AS cart_Page, -- Creating flags for each page
CASE WHEN pageview_url='/shipping' THEN 1 ELSE 0 END AS shipping_Page, -- Creating flags for each page
CASE WHEN pageview_url='/billing' THEN 1 ELSE 0 END AS billing_Page, -- Creating flags for each page
CASE WHEN pageview_url='/thank-you-for-your-order' THEN 1 ELSE 0 END AS thank_you_Page -- Creating flags for each page
FROM website_sessions
LEFT JOIN website_pageviews
ON website_sessions.website_session_id=website_pageviews.website_session_id
WHERE website_sessions.created_at BETWEEN '2012-08-05' AND '2012-09-05'
AND utm_source='gsearch'
AND utm_campaign='nonbrand';
-- AND pageview_url IN ('/lander-1','/products','/the-original-mr-fuzzy','/cart','/shipping','/billing','/thank-you-for-your-order') this line is redudant since the request needs the whole process starting from the products till thank you

-- STEP 3: Create Session-Level conversion funnel view

-- We will put the previous Query into a subquery then use MAX to identify which page did each website session reached

SELECT
website_session_id,
MAX(Products_Page) AS product_made_it,
MAX(Mr_Fuzzy_Page) AS Mr_Fuzzy_made_it,
MAX(cart_Page) AS cart_made_it,
MAX(shipping_Page) AS shipping_made_it,
MAX(billing_Page) AS billing_made_it,
MAX(thank_you_Page) AS thank_you_made_it
FROM(
SELECT
website_sessions.website_session_id,
website_pageviews.pageview_url,
CASE WHEN pageview_url='/products' THEN 1 ELSE 0 END AS Products_Page, -- Creating flags for each page
CASE WHEN pageview_url='/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS Mr_Fuzzy_Page, -- Creating flags for each page
CASE WHEN pageview_url='/cart' THEN 1 ELSE 0 END AS cart_Page, -- Creating flags for each page
CASE WHEN pageview_url='/shipping' THEN 1 ELSE 0 END AS shipping_Page, -- Creating flags for each page
CASE WHEN pageview_url='/billing' THEN 1 ELSE 0 END AS billing_Page, -- Creating flags for each page
CASE WHEN pageview_url='/thank-you-for-your-order' THEN 1 ELSE 0 END AS thank_you_Page -- Creating flags for each page
FROM website_sessions
LEFT JOIN website_pageviews
ON website_sessions.website_session_id=website_pageviews.website_session_id
WHERE website_sessions.created_at BETWEEN '2012-08-05' AND '2012-09-05'
AND utm_source='gsearch'
AND utm_campaign='nonbrand') AS PageView_Level
GROUP BY website_session_id;

-- STEP 4: Aggregate the data to asses the funnel performance
-- We will create a temporary table of the previous query


CREATE TEMPORARY TABLE session_level_made_it_with_Flags
SELECT
website_session_id,
MAX(Products_Page) AS product_made_it,
MAX(Mr_Fuzzy_Page) AS Mr_Fuzzy_made_it,
MAX(cart_Page) AS cart_made_it,
MAX(shipping_Page) AS shipping_made_it,
MAX(billing_Page) AS billing_made_it,
MAX(thank_you_Page) AS thank_you_made_it
FROM(
SELECT
website_sessions.website_session_id,
website_pageviews.pageview_url,
CASE WHEN pageview_url='/products' THEN 1 ELSE 0 END AS Products_Page, -- Creating flags for each page
CASE WHEN pageview_url='/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS Mr_Fuzzy_Page, -- Creating flags for each page
CASE WHEN pageview_url='/cart' THEN 1 ELSE 0 END AS cart_Page, -- Creating flags for each page
CASE WHEN pageview_url='/shipping' THEN 1 ELSE 0 END AS shipping_Page, -- Creating flags for each page
CASE WHEN pageview_url='/billing' THEN 1 ELSE 0 END AS billing_Page, -- Creating flags for each page
CASE WHEN pageview_url='/thank-you-for-your-order' THEN 1 ELSE 0 END AS thank_you_Page -- Creating flags for each page
FROM website_sessions
LEFT JOIN website_pageviews
ON website_sessions.website_session_id=website_pageviews.website_session_id
WHERE website_sessions.created_at BETWEEN '2012-08-05' AND '2012-09-05'
AND utm_source='gsearch'
AND utm_campaign='nonbrand') AS PageView_Level
GROUP BY website_session_id;

-- Start the Counting
SELECT
COUNT(DISTINCT website_session_id) As Total_Number_of_Sessions,
COUNT(DISTINCT CASE WHEN product_made_it=1 THEN website_session_id ELSE NULL END) AS Made_it_to_products,
COUNT(DISTINCT CASE WHEN Mr_Fuzzy_made_it=1 THEN website_session_id ELSE NULL END) AS Made_it_to_Mr_Fuzzy,
COUNT(DISTINCT CASE WHEN cart_made_it=1 THEN website_session_id ELSE NULL END) AS Made_it_to_cart,
COUNT(DISTINCT CASE WHEN shipping_made_it=1 THEN website_session_id ELSE NULL END) AS Made_it_to_shipping,
COUNT(DISTINCT CASE WHEN billing_made_it=1 THEN website_session_id ELSE NULL END) AS Made_it_to_billing,
COUNT(DISTINCT CASE WHEN thank_you_made_it=1 THEN website_session_id ELSE NULL END) AS Made_it_to_thank_you
FROM session_level_made_it_with_Flags;

-- To calculate the Click Rates, repeat the previous query with small modifications:

SELECT
COUNT(DISTINCT website_session_id) As Total_Number_of_Sessions,
COUNT(DISTINCT CASE WHEN product_made_it=1 THEN website_session_id ELSE NULL END)/ COUNT(DISTINCT website_session_id) AS lander_click_rate,
COUNT(DISTINCT CASE WHEN Mr_Fuzzy_made_it=1 THEN website_session_id ELSE NULL END)/ COUNT(DISTINCT CASE WHEN product_made_it=1 THEN website_session_id ELSE NULL END) AS product_click_rate,
COUNT(DISTINCT CASE WHEN cart_made_it=1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN Mr_Fuzzy_made_it=1 THEN website_session_id ELSE NULL END) AS mr_fuzzy_click_rate,
COUNT(DISTINCT CASE WHEN shipping_made_it=1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN cart_made_it=1 THEN website_session_id ELSE NULL END) AS cart_click_rate,
COUNT(DISTINCT CASE WHEN billing_made_it=1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN shipping_made_it=1 THEN website_session_id ELSE NULL END) AS shipping_click_rate,
COUNT(DISTINCT CASE WHEN thank_you_made_it=1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN billing_made_it=1 THEN website_session_id ELSE NULL END) AS billing_click_rate
FROM session_level_made_it_with_Flags;

-- Conclusion to Objective (6):
-- The focus should be on the lander page, mr fuzzy page and billing page as these 3 pages had the lowest click_rate

-- -----------------------------------------------------------------------------------------------------------------------------

-- Main Objective (7): Analyzing Conversion Funnels Test

-- Task: An Email was sent on November 10-2012 from the Website Manager: Morgan Rockwell and it includes the following:

-- We tested an updated billing page based on your funnel analysis. Can you take a look and see whether /billing 2 is doing any better than the original /billing page?
-- We’re wondering what % of sessions on those pages end up placing an order . FYI we ran this test for all traffic, not just for our search visitors

-- -----------------------------------------------------------------------------------------------------------------------------

-- Solution Starts:

-- Finding the first time /billing-2 was seen
SELECT
website_session_id,
MIN(website_pageview_id) as First_pageview_id,
min(created_at) as first_created_at
from website_pageviews
WHERE pageview_url='/billing-2';

-- Results showed that the first_pageview_id was 53550

-- Next step is to apply Criteria to get the relevant sessions
SELECT
website_pageviews.website_session_id,
website_pageviews.pageview_url AS Billing_version_Seen,
orders.order_id
FROM website_pageviews
LEFT JOIN orders
ON orders.website_session_id=website_pageviews.website_session_id
WHERE website_pageviews.website_pageview_id >= 53550
AND website_pageviews.created_at < '2012-11-10'
AND website_pageviews.pageview_url IN ('/billing','/billing-2');

-- we will put the previous query into a subquery

SELECT
Billing_version_Seen,
COUNT(DISTINCT website_session_id) AS Number_of_Sessions,
COUNT(DISTINCT order_id) AS Number_of_Orders,
COUNT(DISTINCT order_id) /COUNT(DISTINCT website_session_id) AS Billing_to_Order_Rate
FROM(

SELECT
website_pageviews.website_session_id,
website_pageviews.pageview_url AS Billing_version_Seen,
orders.order_id
FROM website_pageviews
LEFT JOIN orders
ON orders.website_session_id=website_pageviews.website_session_id
WHERE website_pageviews.website_pageview_id >= 53550
AND website_pageviews.created_at < '2012-11-10'
AND website_pageviews.pageview_url IN ('/billing','/billing-2')) AS Billing_session_With_orders
GROUP BY Billing_version_Seen;

-- Conclusion to Objective (7):
-- The new billing page has higher conversion rate than the old one

-- -----------------------------------------------------------------------------------------------------------------------------




