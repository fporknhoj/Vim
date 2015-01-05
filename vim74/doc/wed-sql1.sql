
SELECT [02A01-Master Tbl].OrderNumber,
       RTRIM([02A01-Master Tbl].OriginRampMarket)+
       RTRIM([02A01-Master Tbl].DestinationRampMarket) AS [Ramp Key],
       [02A01-Master Tbl].OriginRampMarket,
       [02A01-Master Tbl].OriginRampSubMarket,
       [02A01-Master Tbl].DestinationRampSubMarket,
       [02A01-Master Tbl].DestinationRampMarket,
       [02A01-Master Tbl].OriginRampMarket+[02A01-Master Tbl].OriginRampSubMarket+[02A01-Master Tbl].DestinationRampSubMarket+[02A01-Master Tbl].DestinationRampMarket AS [RSSR Key],
       [02A01-Master Tbl].[Total LH+Fuel Margin] AS Margin
	[02A01-Master Tbl].[LH MIN COST]
LH MIN FUEL COST
LH MIN FUEL COST
LH 







INTO T100
FROM [02A01-Master Tbl]
WHERE ((([02A01-Master Tbl].[LH BLENDED COST])>0))
GROUP BY [02A01-Master Tbl].OrderNumber,
 [02A01-Master Tbl].[Ramp Key],
 [02A01-Master Tbl].OriginRampMarket,
 [02A01-Master Tbl].OriginRampSubMarket,
 [02A01-Master Tbl].DestinationRampSubMarket,
 [02A01-Master Tbl].DestinationRampMarket,
 [02A01-Master Tbl].[Total LH+Fuel Margin],
 [02A01-Master Tbl].[Ramp Outlier]
HAVING ((([02A01-Master Tbl].[Ramp Outlier])="N"));
