select count(*)
from olist_order_items_dataset
group by order_id ;
--- 전체 주문 112650개
---  order_id당 주문2개인것 있음.
---  order_id가 같고, product_id도 같은경우 있음. 같은상품 여러개사면 order_item_id만 늘어남. 즉제품하나.
--- 그럼 날짜별 주문건수 추이 확인해보자.
-- > 그건여기서 확인못해.orders datset으로 간다
select count(unique customer_id)
from olist_orders_dataset;
--- > orders_dataset 테이블 customer_id는 99441개(중복없이)
select count(*)
from olist_orders_dataset;
--> 전체 행도 99441개.
select count(unique order_id)
from olist_orders_dataset;

select count(order_id)
from olist_orders_dataset
group by order_id
order by count(order_id) desc ;
-->orders dataset의 order id도 각자1개다, 중복없다.

--->1.날짜별 구매자수 구해그래프기려보자 
select to_char(order_purchase_timestamp,'YYYY-MM') as order_month, count(customer_id)
from olist_orders_dataset
group by to_char(order_purchase_timestamp,'YYYY-MM')
order by order_month;
--> groupby에 없는ㄱㄴ select에 집계함수로 가능 
 
--->2.배송완료고객만 쓰자. 2-1.배송완료주문
select count(distinct order_id),count(distinct customer_id)
from olist_orders_dataset
where olist_orders_dataset.order_status = 'delivered' ;
--> 문자는 작은따옴표.
--> customer_id가 개인당1개가 아닌가?
--2-2. 배송완료에 해당하는 고객
select count(distinct customer_id),count(distinct customer_unique_id)
from olist_customers_dataset;
--> customer_id랑 customer_unique_id다름. 개별고객은 customer_unique_id로 판별.!!!
select count(distinct C.customer_unique_id)
from (select *
        from  olist_orders_dataset
        where olist_orders_dataset.order_status = 'delivered') O,
        olist_customers_dataset C
where O.customer_id = C.customer_id;

---3 RFM컬럼 만들기
---3-1. 우선 고유고객이 쓴 금액가져와야함.
select customer_unique_id
from olist_customers_dataset;
--금액보려면 order_id와 cutomer_id,unique_id연결
---olist_orders_dataset의 order_id,olist_order_items_dataset의 price order_id별로 sum,
---- olist orders dataset은 order_id, customer_id있으니 중간에서 customers_dataest과 order_item_dataset사이 연결.
select count(distinct C.customer_unique_id)
from olist_orders_dataset O, olist_customers_dataset C, olist_order_items_dataset I
where O.order_id = I.order_id 
and O.customer_id = C.customer_id
and O.order_status='delivered';
--- M구하기
select C.customer_unique_id, sum(I.price) as Monetary
from olist_orders_dataset O, olist_customers_dataset C, olist_order_items_dataset I
where O.order_id = I.order_id 
and O.customer_id = C.customer_id
and O.order_status='delivered'
group by C.customer_unique_id
order by Monetary desc;

select *
from olist_orders_dataset O, olist_customers_dataset C, olist_order_items_dataset I
where O.order_id = I.order_id 
and O.customer_id = C.customer_id
and O.order_status='delivered'
and C.customer_unique_id = 'b38211bd797f4fdd81a98b9d1754b606';

select *
from olist_products_dataset
where  product_id = '8a3254bee785a526d548a81a9bc3c9be';

--order_payments_dataset으로 바꿔야할듯 sum(price) 0.85원 200원나옴오류
--- M구하기2
select C.customer_unique_id, sum(P.payment_value) as Monetary
from olist_orders_dataset O, olist_customers_dataset C, olist_order_payments_dataset P
where O.order_id = P.order_id 
and O.customer_id = C.customer_id
and O.order_status='delivered'
group by C.customer_unique_id
order by Monetary asc;  --굳 잘나옴.

---3-2. F구하기.(M도 나옴)    
select C.customer_unique_id,count(C.customer_unique_id) as Frequency, sum(P.payment_value) as Monetary
from olist_orders_dataset O, olist_customers_dataset C, olist_order_payments_dataset P
where O.order_id = P.order_id 
and O.customer_id = C.customer_id
and O.order_status='delivered'
group by C.customer_unique_id
order by Frequency desc;

----3-3 R 구하기전..
--->1.날짜별 구매자수 구해그래프기려보자 ###위에서 가져옴.데이터 2018년8월까지만 수행해야할것같은데? 전처리수정필요. 
--- 2017-01부터 2018 08까지만..
select to_char(order_purchase_timestamp,'YYYY-MM') as order_month, count(customer_id)
from olist_orders_dataset
group by to_char(order_purchase_timestamp,'YYYY-MM')
order by order_month;
--> groupby에 없는ㄱㄴ select에 집계함수로 가능 

--- 
select count(distinct customer_unique_id)
from olist_orders_dataset O, olist_customers_dataset C
where O.customer_id = C.customer_id
and O.order_status='delivered'
and O.order_purchase_timestamp >= TO_DATE('2017-01-01','YYYY-MM-DD')
and O.order_purchase_timestamp < TO_DATE('2018-09-01','YYYY-MM-DD');
--->##총93104명 인원

---재구매인원은?
select count(*)
from (
select count(distinct O.order_id), C.customer_unique_id
from olist_orders_dataset O, olist_customers_dataset C 
where O.customer_id = C.customer_id
and O.order_status='delivered'
and O.order_purchase_timestamp >= TO_DATE('2017-01-01','YYYY-MM-DD')
and O.order_purchase_timestamp < TO_DATE('2018-09-01','YYYY-MM-DD')
group by C.customer_unique_id
having count(distinct O.order_id)>=2
);

---4.R구하기. 최종일부터. 18/08/29가 최종이네.
select order_purchase_timestamp
from olist_orders_dataset O, olist_customers_dataset C, olist_order_payments_dataset P
where O.order_id = P.order_id 
and O.customer_id = C.customer_id
and O.order_status='delivered'
and O.order_purchase_timestamp >= TO_DATE('2017-01-01','YYYY-MM-DD')
and O.order_purchase_timestamp < TO_DATE('2018-09-01','YYYY-MM-DD')
order by order_purchase_timestamp desc;
---4-2. R 최종본(파이썬으로 옮겨
select customer_unique_id, TRUNC(TO_DATE('2018-08-30','YYYY-MM-DD')) -TRUNC(MAX(order_purchase_timestamp)) as Recency, 
count(C.customer_unique_id) as Frequency, 
sum(P.payment_value) as Monetary
from olist_orders_dataset O, olist_customers_dataset C, olist_order_payments_dataset P
where O.order_id = P.order_id 
and O.customer_id = C.customer_id
and O.order_status='delivered'
and O.order_purchase_timestamp >= TO_DATE('2017-01-01','YYYY-MM-DD')
and O.order_purchase_timestamp < TO_DATE('2018-09-01','YYYY-MM-DD')
group by customer_unique_id
order by Recency desc, frequency desc, monetary desc;
--->>중복있대.수정하자.
-->M만따로 테이블맘ㄴ든후 조인하면 될듯
with Payment_view as 
(select order_id, sum(payment_value) Monetary
from olist_order_payments_dataset
group by order_id
)
select customer_unique_id, TRUNC(TO_DATE('2018-08-30','YYYY-MM-DD')) -TRUNC(MAX(order_purchase_timestamp)) as Recency, 
count(C.customer_unique_id) as Frequency, 
sum(P.Monetary) as Monetary
from olist_orders_dataset O, olist_customers_dataset C, Payment_view P
where O.order_id = P.order_id 
and O.customer_id = C.customer_id
and O.order_status='delivered'
and O.order_purchase_timestamp >= TO_DATE('2017-01-01','YYYY-MM-DD')
and O.order_purchase_timestamp < TO_DATE('2018-09-01','YYYY-MM-DD')
group by customer_unique_id
order by Recency desc, frequency desc, monetary desc;
--(최종RFM)

-->우선구매날짜별 주문.
select to_char(order_purchase_timestamp,'YYYY-MM')
from olist_orders_dataset O
where O.order_status='delivered'
and O.order_purchase_timestamp >= TO_DATE('2017-01-01','YYYY-MM-DD')
and O.order_purchase_timestamp < TO_DATE('2018-09-01','YYYY-MM-DD');