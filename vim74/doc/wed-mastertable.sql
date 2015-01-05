
SELECT [01A01-LH Revenue Tbl].OrderNumber,
 [01A01-LH Revenue Tbl].DSRDate,
 Trim([01A01-LH Revenue Tbl]!OriginRampMarket) & Trim([01A01-LH Revenue Tbl]!OriginRampSubMarket) & Trim([01A01-LH Revenue Tbl]!DestinationRampMarket) & Trim([01A01-LH Revenue Tbl]!DestinationRampSubMarket) AS [Ramp Key],
 "" AS [Ramp Outlier],
 [01A01-LH Revenue Tbl]!OriginZoneNumber & Trim([01A01-LH Revenue Tbl]!OriginRampMarket) & Trim([01A01-LH Revenue Tbl]!OriginRampSubMarket) & Trim([01A01-LH Revenue Tbl]!DestinationRampMarket) & Trim([01A01-LH Revenue Tbl]!DestinationRampSubMarket) & [01A01-LH Revenue Tbl]!DestinationZoneNumber AS [ZRRZ Key],
 "" AS [ZRRZ Outlier],
 0 AS Quartile,
 0 AS [ZRRZ Quartile],
 [01A01-LH Revenue Tbl]!OriginCityMultiple & ", " & [01A01-LH Revenue Tbl]!OriginState & "-" & [01A01-LH Revenue Tbl]!DestinationCityMultiple & ", " & [01A01-LH Revenue Tbl]!DestinationState AS [Lane Key],
 [01A01-LH Revenue Tbl].ReportingCustomerNumber,
 [01A01-LH Revenue Tbl].ReportingCustomerName,
 [01A01-LH Revenue Tbl].CustomerNumber,
 [01A01-LH Revenue Tbl].CustomerName,
 [01A05-LH Cost Tbl].[Big Fleet Cust],
 [01A01-LH Revenue Tbl].OriginCityMultiple,
 [01A01-LH Revenue Tbl].OriginState,
 [01A01-LH Revenue Tbl].[5D O Zip],
 [01A01-LH Revenue Tbl].OriginCountryCode,
 [01A01-LH Revenue Tbl].DestinationCityMultiple,
 [01A01-LH Revenue Tbl].DestinationState,
 [01A01-LH Revenue Tbl].[5D D Zip],
 [01A01-LH Revenue Tbl].DestinationCountryCode,
 [01A01-LH Revenue Tbl].ServiceType,
 [01A01-LH Revenue Tbl].OriginZoneNumber,
 [01A01-LH Revenue Tbl].OriginZoneName,
 [01A01-LH Revenue Tbl].OriginRampMarket,
 [01A01-LH Revenue Tbl].OriginRampSubMarket,
 [01A01-LH Revenue Tbl].DestinationRampMarket,
 [01A01-LH Revenue Tbl].DestinationRampSubMarket,
 [01A01-LH Revenue Tbl].DestinationZoneNumber,
 [01A01-LH Revenue Tbl].DestinationZoneName,
 [01A01-LH Revenue Tbl].EquipmentProvider,
 [01A01-LH Revenue Tbl].Mileage,
 [01A03-ODR Cost Tbl].OriginRampSCAC,
 [01A03-ODR Cost Tbl].[CMKI/NON-CMKI] AS [ODR CMKI/NON-CMKI],
 [01A03-ODR Cost Tbl].[ODR Dray $01],
 [01A04-DDR Cost Tbl].[CMKI/NON-CMKI] AS [DDR CMKI/NON-CMKI],
 [01A04-DDR Cost Tbl].[DDR Dray $01],
 [01A01-LH Revenue Tbl].[LH Revenue],
 [01A02-FSC Revenue Tbl].[FSC Revenue],
 [01A03-ODR Cost Tbl].[ODR COST],
 [01A07-ODR FSC Cost Tbl].[ODR FSC COST],
 [01A03-ODR Cost Tbl].[ODR BLENDED COST],
 [01A07-ODR FSC Cost Tbl].[ODR BLENDED FUEL COST],
 [01A05-LH Cost Tbl].[Interline or Local],
 [01A05-LH Cost Tbl].[EQ Group],
 [01A05-LH Cost Tbl].[LH Segment Miles],
 [01A05-LH Cost Tbl].[LH COST],
 [01A05-LH Cost Tbl].[LH MIN COST],
 [01A05-LH Cost Tbl].[LH BLENDED COST],
 [01A09-LH FSC Cost Tbl].[LH FSC COST],
 [01A09-LH FSC Cost Tbl].[LH MIN FUEL COST],
 [01A09-LH FSC Cost Tbl].[LH BLENDED FUEL COST],
 [01A09-LH FSC Cost Tbl].MinRPU,
 [01A09-LH FSC Cost Tbl].MinRPUFuel,
 [01A06-EQ Costs Tbl].[EQ COST],
 [01A06-EQ Costs Tbl].[EQ MIN COST],
 [01A06-EQ Costs Tbl].[EQ BLENDED COST],
 [01A04-DDR Cost Tbl].[DDR COST],
 [01A08-DDR FSC Cost Tbl].[DDR FSC COST],
 [01A04-DDR Cost Tbl].[DDR BLENDED COST],
 [01A08-DDR FSC Cost Tbl].[DDR BLENDED FUEL COST],
 [01A04-DDR Cost Tbl].[DDR Miles Used],
 CCur(0) AS [Total LH+Fuel Revenue],
 CCur(0) AS [Total LH Cost],
 CCur(0) AS [Total Fuel Cost],
 CCur(0) AS [Total LH+Fuel Cost],
 CCur(0) AS [Total LH Margin],
 CCur(0) AS [Total Fuel Margin],
 CCur(0) AS [Total LH+Fuel Margin],
 [01A05-LH Cost Tbl].JunctionSCAC1,
 [01A05-LH Cost Tbl].JunctionSCAC2,
 [01A05-LH Cost Tbl].JunctionSCAC3,
 [01A05-LH Cost Tbl].JunctionSCAC4 INTO [02A01-Master Tbl]
FROM ((((((([01A01-LH Revenue Tbl] LEFT JOIN [01A02-FSC Revenue Tbl] ON [01A01-LH Revenue Tbl].OrderNumber = [01A02-FSC Revenue Tbl].OrderNumber) LEFT JOIN [01A03-ODR Cost Tbl] ON [01A01-LH Revenue Tbl].OrderNumber = [01A03-ODR Cost Tbl].OrderNumber) LEFT JOIN [01A06-EQ Costs Tbl] ON [01A01-LH Revenue Tbl].OrderNumber = [01A06-EQ Costs Tbl].OrderNumber) LEFT JOIN [01A04-DDR Cost Tbl] ON [01A01-LH Revenue Tbl].OrderNumber = [01A04-DDR Cost Tbl].OrderNumber) LEFT JOIN [01A09-LH FSC Cost Tbl] ON [01A01-LH Revenue Tbl].OrderNumber = [01A09-LH FSC Cost Tbl].OrderNumber) LEFT JOIN [01A07-ODR FSC Cost Tbl] ON [01A01-LH Revenue Tbl].OrderNumber = [01A07-ODR FSC Cost Tbl].OrderNumber) LEFT JOIN [01A08-DDR FSC Cost Tbl] ON [01A01-LH Revenue Tbl].OrderNumber = [01A08-DDR FSC Cost Tbl].OrderNumber) LEFT JOIN [01A05-LH Cost Tbl] ON [01A01-LH Revenue Tbl].OrderNumber = [01A05-LH Cost Tbl].OrderNumber
WHERE ((([01A01-LH Revenue Tbl].[LH Revenue])>99) AND (([01A02-FSC Revenue Tbl].[FSC Revenue])>0));