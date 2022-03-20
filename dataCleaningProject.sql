-- DATA CLEANING: SQL QUERIES

SELECT * FROM dataCleaningProject.dbo.housing


-- STANDARDIZE DATE FORMAT (remove time in the format)
SELECT ConvertedDate
FROM dataCleaningProject.dbo.housing

-- added a column
ALTER TABLE dataCleaningProject.dbo.housing
ADD ConvertedDate Date;

--set value to the added column
UPDATE housing
SET ConvertedDate = CONVERT(Date,SaleDate)


-- POPULATE PROPERTY ADDRESS DATA
SELECT *
FROM dataCleaningProject.dbo.housing
WHERE PropertyAddress is null -- might be an issue in reference point

-- checking if there are NULL in property address
SELECT firstJoin.ParcelID, firstJoin.PropertyAddress, secondJoin.ParcelID, secondJoin.PropertyAddress
, ISNULL(firstJoin.PropertyAddress, secondJoin.PropertyAddress)
FROM dataCleaningProject.dbo.housing firstJoin
-- joining same tables
JOIN dataCleaningProject.dbo.housing secondJoin
	ON firstJoin.ParcelID = secondJoin.ParcelID
	AND firstJoin.[UniqueID ] <> secondJoin.[UniqueID ]
WHERE firstJoin.PropertyAddress is null

-- combine property address available into null, to remove NULL
UPDATE firstJoin -- updating the table containing nulls
SET PropertyAddress = ISNULL(firstJoin.PropertyAddress, secondJoin.PropertyAddress)
FROM dataCleaningProject.dbo.housing firstJoin
JOIN dataCleaningProject.dbo.housing secondJoin
	ON firstJoin.ParcelID = secondJoin.ParcelID
	AND firstJoin.[UniqueID ] <> secondJoin.[UniqueID ]
WHERE firstJoin.PropertyAddress is null


-- BREAKING OUT ADDRESS INTO INDIVIDUAL COLUMNS (address, city, state)
-- use substring & charindex
SELECT PropertyAddress
FROM dataCleaningProject..housing

-- select characters before the 'comma'
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS Address  -- +1 to not include comma
FROM dataCleaningProject..housing

-- add 2 columns
-- 1st column - for property address
ALTER TABLE dataCleaningProject.dbo.housing
ADD SplitPropAddress Nvarchar(255);

UPDATE dataCleaningProject.dbo.housing
SET SplitPropAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

-- 2nd column - for city
ALTER TABLE dataCleaningProject.dbo.housing
ADD SplitCity Nvarchar(255);

--set value to the added column
UPDATE dataCleaningProject.dbo.housing
SET SplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

SELECT *
FROM dataCleaningProject.dbo.housing


SELECT OwnerAddress
FROM dataCleaningProject.dbo.housing

-- testing parsename
SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)
, PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)
, PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
FROM dataCleaningProject.dbo.housing


-- owner split address
ALTER TABLE dataCleaningProject.dbo.housing
ADD ownerSplitAddress Nvarchar(255);

UPDATE dataCleaningProject.dbo.housing
SET ownerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)

-- owner split city
ALTER TABLE dataCleaningProject.dbo.housing
ADD ownerSplitCity Nvarchar(255);

UPDATE dataCleaningProject.dbo.housing
SET ownerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)

-- owner split state
ALTER TABLE dataCleaningProject.dbo.housing
ADD ownerSplitState Nvarchar(255);

UPDATE dataCleaningProject.dbo.housing
SET ownerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)

SELECT *
FROM dataCleaningProject.dbo.housing


-- CHANGE Y & N TO Yes & No in "Sold as Vacant"

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM dataCleaningProject.dbo.housing
GROUP BY SoldAsVacant
ORDER BY 2

-- like an ifelse statement
SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
FROM dataCleaningProject.dbo.housing

-- change y and n to yes and no
UPDATE dataCleaningProject.dbo.housing
SET SoldAsVacant =
	   CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END


-- REMOVE DUPLICATES
-- WARNING: Deleting data isn't good practice, this is just for practicing

-- QUERY FOR CTE
WITH CTERow AS (
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
			ORDER BY
				UniqueID
) row_num

FROM dataCleaningProject.dbo.housing
)
SELECT *
FROM CTERow
WHERE row_num > 1


-- DELETE UNUSED COLUMNS
-- WARNING: Don't use on raw data

SELECT *
FROM dataCleaningProject.dbo.housing

ALTER TABLE dataCleaningProject.dbo.housing
DROP COLUMN SaleDate


SELECT [UniqueID ], SplitPropAddress, SplitCity, SalePrice, LegalReference
, LandValue, BuildingValue, TotalValue, YearBuilt, Bedrooms
FROM dataCleaningProject.dbo.housing
ORDER BY SalePrice DESC