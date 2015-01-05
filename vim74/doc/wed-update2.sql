
UPDATE [02A01-Master Tbl] SET [02A01-Master Tbl].[Total LH Margin] = [02A01-Master Tbl].[LH Revenue]-[02A01-Master Tbl].[Total LH Cost],
 [02A01-Master Tbl].[Total Fuel Margin] = [02A01-Master Tbl].[FSC Revenue]-[02A01-Master Tbl].[Total Fuel Cost],
 [02A01-Master Tbl].[Total LH+Fuel Margin] = [02A01-Master Tbl].[Total LH+Fuel Revenue]-[02A01-Master Tbl].[Total LH+Fuel Cost]
WHERE ((([02A01-Master Tbl].[LH BLENDED COST])>0));
