-- who is the senior most employee based on the job title?-- use employee table

select * from employee
order by levels desc
limit 1;

-- Which countries have the most Invoices?--use invoice table

select billing_country,count(*)  as no_of_invoice from invoice
group by 1
order by 2 desc
limit 1;

--What are top 3 values of total invoice? --use invoice table

select total,* from invoice
order by total desc
limit 3;

/*  Which city has the best customers? We would like to throw a promotional Music Festival 
  in the city we made the most money.Write a query that returns one city that has the highest 
 sum of invoice totals.
Return both the city name & sum of all invoice totals*/ -- use invoice table

select billing_city, sum(total) as Invoice_Total from invoice
group by billing_city
order by 2 desc
limit 1;

/*Who is the best customer? The customer who has spent the most money will be declared 
the best customer.
Write a query that returns the person who has spent the most money.*/
-- use customer and invoice table

select first_name|| ' ' || last_name as Name 
from customer
where customer_id in (
					select customer_id from invoice
					group by 1
					order by sum(total) desc
					limit 1
);

select c.customer_id,c.first_name|| ' ' || c.last_name as Name, sum(i.total)  as Spend
from customer c
join invoice  as i
on c.customer_id = i.customer_id
group by 1
order by 3 desc
limit 1;

/* Write query to return the first name, last name, email 
 and genre of all the Rock Music listners.
Return your list ordered alphabetically by email starting with A.*/
--use customer, invoice, invoice_line,track and genre table

with rock as (
select t.track_id,g.name 
from genre as g
join track as t
on g.genre_id = t.genre_id
and g.name = 'Rock'
	), stone as
(select r.*,il.invoice_id from rock as r
join invoice_line as il
on r.track_id = il.track_id
), paper as (
select s.*,i.customer_id from invoice as i
join stone as s
on s.invoice_id = i.invoice_id
)
select c.first_name || ' ' || c.last_name,  email, name from customer as c
join paper as p 
on c.customer_id = p.customer_id
order by email asc;

select email,first_name ,last_name from customer c
join invoice i on i.customer_id = c.customer_id
join invoice_line il on il.invoice_id = i.invoice_id
where il.track_id in (
	select track_id from track t
    join genre g on t.genre_id = g.genre_id and g.name = 'Rock'  )
	order by email;

/* Let's invite the artists who have written the most rock music in our data set. 
 Write a query that returns the artist name and total track count of the top 10 rock bands*/
 
with one as(
select track_id from track t
join genre g on t.genre_id = g.genre_id and g.name = 'Rock'), two as(

select art.name,t.track_id from album as al
join artist as art
on art.artist_id = al.artist_id
join track as t
on al.album_id = t.album_id)

select two.name,count(one.track_id) from one
join two
on two.track_id = one.track_id
group by 1
order by 2 desc
limit 10;

/* Return all the track names that have a song length longer than average song length.
Return the name and track_id of each track.
order by song length with the 
*/

select milliseconds,track_id,name from track
where milliseconds > (select avg(milliseconds) from track)
order by milliseconds desc;

/* Find how much amount spent by each customer on artists? 
Write a query to return customer name, artist name and total spent?
*/

with best_selling_artist as (
select art.artist_id as artist_id,art.name as artist_name, 
sum(il.unit_price * il.quantity)as total_sale from invoice_line as il
join track as t on t.track_id = il.track_id
join album as al on al.album_id = t.album_id
join artist as art on art.artist_id = al.artist_id
group by 1
order by 3 desc
limit 1)
select c.customer_id,c.first_name || ' ' || c.last_name as Name,bsa.artist_name,
sum(il.unit_price * il.quantity) from customer c
join invoice i on i.customer_id =c.customer_id
join invoice_line il on il.invoice_id = i.invoice_id
join track t on t.track_id = il.track_id
join album al on al.album_id = t.album_id
join best_selling_artist bsa on bsa.artist_id = al.artist_id
group by 1,3
order by 4 desc;

/* We want to find out the most popular music Genre for each country.
We determine the most popular Genre as the genre with the highest amount of purchases.
Write a query that returns each country long with the top Genre.
For countries where the maximum no. of purchases is shared return all Genres.
*/
--Method 1
with sales_per_country as(
select i.billing_country,g.genre_id,g.name,count(il.quantity) as purchases_per_genre 
	from invoice as i
join invoice_line as il on il.invoice_id = i.invoice_id
join track as t on t.track_id = il.track_id
join genre as g on g.genre_id = t.genre_id
group by 1,2
order by 1,4 desc) , max_genre_per_country as (
select max(purchases_per_genre) as max_genre_number,billing_country from sales_per_country
	group by 2
	order by 2
)
select sales_per_country.* from sales_per_country
join max_genre_per_country 
on sales_per_country.billing_country = max_genre_per_country.billing_country
where sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number

--Method 2

WITH popular_genre AS 
(
 SELECT COUNT(invoice_line.quantity) AS purchases, customer.country, genre.name, genre.genre_id, 
ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) 
	AS RowNo 
    FROM invoice_line 
	JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
	JOIN customer ON customer.customer_id = invoice.customer_id
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY 2,3,4
	ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM popular_genre WHERE RowNo <= 1;

/* Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount.*/

with customer_with_country  as (
select c.customer_id,c.first_name || ' ' || last_name as name,c.country ,sum(i.total) as total_spending from customer as c
join invoice as i
on i.customer_id = c.customer_id
group by 1,2
order by 3 )
, country_max_spending as(
	select max(total_spending) as max_spending,country from customer_with_country
group by 2)
select customer_with_country.* from customer_with_country
join country_max_spending on customer_with_country.country = country_max_spending.country
and country_max_spending.max_spending = customer_with_country.total_spending
order by 1;


WITH Customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending,
	    ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo 
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 4 ASC,5 DESC)
SELECT * FROM Customter_with_country WHERE RowNo <= 1
order by 1