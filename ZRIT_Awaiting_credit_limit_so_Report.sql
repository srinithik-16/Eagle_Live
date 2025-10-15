/******************************************************************/
/* 
Rtrack			: ECE-5409
Date			: 14-10-2025
Description		: Report for fetching Sale orders that in Awaiting Credit Limit status 
and previously undergone Awaiting credit limit changes 	
Author			: Srinidhi.B
*/
/*******************************************************************/
--exec ZRIT_Awaiting_credit_limit_so_Report 'ecc','','',''

--EXEC sp_rename 'Awaiting_credit_limit_so_Report', 'ZRIT_Awaiting_credit_limit_so_Report';

CREATE or ALTER  PROCEDURE  ZRIT_Awaiting_credit_limit_so_Report
 @company			varchar(100)
,@customercode		varchar(1000)
,@sofrom			Datetime
,@soto				Datetime
AS 
BEGIN
SET NOCOUNT ON 

 if @customercode    in('ALL', '',' ', ' ','~#~', '%')                                      
 begin                                      
  select @customercode   = NULL                                   
 end
 
  if @sofrom    in('1900-01-01')                                      
 begin                                      
  select @sofrom   = NULL                                  
 end 

  if @soto    in('1900-01-01')                                      
 begin                                      
  select @soto   =  NULL                                  
 end 

SELECT  
a.sohdr_ou										'Ou_id'
,sohdr_bill_to_cust								'Parent_Customer_Code'
,convert(varchar(100), '')						'Parent_Customer_Name'
,sohdr_order_from_cust							'Customer_Code'
,Cust_name										'Customer Name'
,sohdr_order_date								'Sale order date'
,sohdr_order_no									'Sale order No'
,sodtl_item_code								'Item_Code'
,convert(varchar(100), '')						'Itemdesc'
,sohdr_sales_channel							'Sales Channel'
,sohdr_freight_method							'Freight Method'
,sohdr_pay_term_code							'Payment Term'
,convert(varchar(100), '')						'Delivery_area'
,sodtl_ship_wh_no_dflt							'Shipment Factory'
,sohdr_ship_to_id_dflt							'Shipto_Id'
,convert(varchar(100), '')						'Shipto_Name'
,sohdr_order_total_qty							'Quantity'
,sohdr_total_value								'Price'
,(sohdr_total_value/sohdr_order_total_qty)		'Value'
,cONVERT(varchar(1000),sohdr_order_status)   	'Status'
,sohdr_created_by								'Created By'
,sohdr_created_date								'Created date&time'
,sohdr_authorize_by								'Authorise by'										
,sohdr_authorize_date							'Authorise date&time'
,sohdr_modified_by								'Modified By'
,sohdr_modified_date							'Modified date&time'
into #temp
FROM 
SCMDB..SO_ORDER_HDR a with (NOLOCK)
JOIN
scmdb..so_order_item_dtl b with (NOLOCK)
ON 
a.sohdr_ou			= b.sodtl_ou
and a.sohdr_order_no	= b.sodtl_order_no

INNER JOIN 
Reportsdb.dbo.SALES_Customer_Master_VIEW E with (NOLOCK)
ON sohdr_order_from_cust = Cust_no

INNER JOIN scmdb..emod_company_ou_bu_lo_vw with (nolock)
ON a.sohdr_ou = ou_id


where sohdr_order_status = 'EX'
OR sohdr_prev_status = 'EX'
and Company_code = @company
AND sohdr_order_from_cust = isnull(@customercode,sohdr_order_from_cust)
AND sohdr_order_date BETWEEN  isnull(@sofrom, sohdr_order_date)   AND  isnull(@soto, sohdr_order_date)               


UPDATE T
SET T.Status = PARAMDESC
from #temp t
LEFT JOIN SCMDB..component_metadata_table  M  (NOLOCK)             
ON  T.Status = M.Paramcode            
AND   m.componentname  = 'nso'                
and   m.paramcategory  = 'status'                
and   m.paramtype   = 'so_status'                
and   m.langid    = 1 


UPDATE T
SET Itemdesc = Itm_itemdesc
from #temp t
join itm_master_vw a with (nolock)
on  t.Item_Code = itm_itemcode


UPDATE T 
SET Delivery_area = addr_del_area_code
FROM #temp T 
JOIN scmdb..cust_addr_dtl a with (nolock)
ON Customer_Code = addr_cust_code


UPDATE T 
SET Shipto_Name = addr_name
FROM #temp T 
JOIN scmdb..cust_addr_dtl  a with (nolock)
ON Customer_Code = addr_cust_code


UPDATE T 
SET Parent_Customer_Name = clo_cust_name
FROM #temp T 
JOIN SCMDB..cust_lo_info A  with (nolock)
ON Customer_Code = clo_cust_code


select * from #temp
 

SET NOCOUNT OFF
END




