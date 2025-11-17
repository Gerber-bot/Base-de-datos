USE Automotors;
GO

;WITH E1(N) AS (SELECT 1 FROM (VALUES(1),(1),(1),(1),(1),(1),(1),(1),(1),(1)) a(n)),
      E2(N) AS (SELECT 1 FROM E1 a CROSS JOIN E1 b),
      E4(N) AS (SELECT 1 FROM E2 a CROSS JOIN E2 b),
      Tally(N) AS (SELECT TOP (5000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM E4)
INSERT INTO Cliente (dni, nombre, apellido, telefono, email, direccion)
SELECT
  RIGHT('00000000' + CAST(30000000 + N AS VARCHAR(10)),8),
  CONCAT('Nombre',N),
  CONCAT('Apellido',N),
  CONCAT('15', RIGHT('000000000' + CAST(N AS VARCHAR(10)),8)),
  CONCAT('cliente',N,'@mail.com'),
  CONCAT('Calle ', N)
FROM Tally;
GO
