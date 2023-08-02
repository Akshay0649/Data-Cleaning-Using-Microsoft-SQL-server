/*
Cleaning Data in SQL Queries
*/
select *
From [Data-Cleaning].dbo.NashvilleHousing
-----------------------------------------------------------------------
--Standardize Date Format

Select SaleDateConverted, CONVERT(Date,SaleDate)
From [Data-Cleaning].dbo.NashvilleHousing

Update NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate)

ALTER TABLE NashvilleHousing
Add SaleDateConverted Date;

Update NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

----------------------------------------------------------------------------------------------
-- populate Property Address Data

Select PropertyAddress
From [Data-Cleaning].dbo.NashvilleHousing
--where PropertyAddress is null
order by ParcelID


Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
From [Data-Cleaning].dbo.NashvilleHousing a 
join [Data-Cleaning].dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null

Update a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
From [Data-Cleaning].dbo.NashvilleHousing a 
join [Data-Cleaning].dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null 

------------------------------------------------------------------------------------
--Breaking Out Address into Individual Columns(Address, City, State)

select PropertyAddress
From [Data-Cleaning].dbo.NashvilleHousing
--where PropertyAddress is null
--order by ParcelID

--Substring similar like character index[is used to search anything like a word - Tom, John)
--CHARINDEX(',', PropertyAddress)) defines positioning

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1,LEN(PropertyAddress)) as Address

FROM [Data-Cleaning].dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
Add PropertySplitAddress Nvarchar(255);

Update NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE NashvilleHousing
Add PropertySplitCity Nvarchar(255);

Update NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1,LEN(PropertyAddress))

select * 
From [Data-Cleaning].dbo.NashvilleHousing

--now we do owner Address it is used to split the address into a 3 different columns based street, city, state 
select OwnerAddress 
From [Data-Cleaning].dbo.NashvilleHousing

select 
PARSENAME(Replace(OwnerAddress, ',', '.'), 3)
,PARSENAME(Replace(OwnerAddress, ',', '.'), 2)
,PARSENAME(Replace(OwnerAddress, ',', '.'), 1)
from [Data-Cleaning].dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
Add OwnerSplitAddress Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitAddress = PARSENAME(Replace(OwnerAddress, ',', '.'), 3)

ALTER TABLE NashvilleHousing
Add OwnerSplitCity Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitCity = PARSENAME(Replace(OwnerAddress, ',', '.'), 2)

ALTER TABLE NashvilleHousing
Add OwnerSplitState Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitState = PARSENAME(Replace(OwnerAddress, ',', '.'), 1)

select *
From [Data-Cleaning].dbo.NashvilleHousing

-----------------------------------------------------------------------------------
--Change Y and N to Yes and No in column "Sold as Vacant" field 

select Distinct(SoldAsVacant), Count(SoldAsVacant)
FROM [Data-Cleaning].dbo.NashvilleHousing
Group by SoldAsVacant
order by 2

Select SoldAsVacant
, CASE when SoldAsVacant = 'Y' Then 'Yes'
       when SoldAsVacant = 'N' Then 'No'
	   ELSE SoldAsVacant
	   END
FROM [Data-Cleaning].dbo.NashvilleHousing

Update NashvilleHousing
SET SoldAsVacant = CASE when SoldAsVacant = 'Y' Then 'Yes'
       when SoldAsVacant = 'N' Then 'No'
	   ELSE SoldAsVacant
	   END
 
 ----------------------------------------------------------------------------------------------

 --Remove Duplicates
With RowNumCTE AS(
 select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID, 
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From [Data-Cleaning].dbo.NashvilleHousing
--order by ParcelID
)
Select *
--Delete
From RowNumCTE
where row_num > 1
--order by PropertyAddress
-- there are 104 rows that are having duplicates

--------------------------------------------------------------------------------------------------

 -- Delete Unused Columns

 select *
 From  [Data-Cleaning].dbo.NashvilleHousing

 ALTER TABLE [Data-Cleaning].dbo.NashvilleHousing
 DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

  ALTER TABLE [Data-Cleaning].dbo.NashvilleHousing
 DROP COLUMN SaleDate
-----------------------------------------------------------------------------------------------------
/*

Data Exploration using SQL

*/

--Find the average value of a house by year.

Select Distinct(YearBuilt), AVG(TotalValue) as AverageValue
From [Data-Cleaning].dbo.NashvilleHousing
Group by YearBuilt
Order by YearBuilt Desc

-----------------------------------------------------------------------------------------
--Average value of a house base on the number of bedrooms and bathrooms

Select Bedrooms, FullBath, AVG(TotalValue) as AvgValue
From [Data-Cleaning].dbo.NashvilleHousing
Group by Bedrooms, FullBath
Order by AvgValue Desc

-------------------------------------------------------------------------------------------------

--See the effect, on total acreage has on house value

Select Acreage, AVG(TotalValue) as AvgValue
From [Data-Cleaning].dbo.NashvilleHousing
Group by Acreage
order by Acreage Desc
--------------------------------------------------------------------------------------------------

--Does the city house is located 

SELECT PropertySplitCity, AVG(TotalValue) as AvgValue
FROM [Data-Cleaning].dbo.NashvilleHousing
GROUP BY PropertySplitCity
ORDER BY AvgValue DESC

--Highest Revenue Generated Month 
--we need to create new column that extracts only the months that houses are sold

ALTER Table [Data-Cleaning].dbo.NashvilleHousing
ADD MonthSold Nvarchar(255);

Update [Data-Cleaning].dbo.NashvilleHousing 
SET Monthsold = PARSENAME(Replace(SaleDateConverted, ',', '.'), 2)

SELECT MonthSold, Count(*) as NumHousesSold
From [Data-Cleaning].dbo.NashvilleHousing
Group By MonthSold
Order by NumHousesSold Desc

--------------------------------------------------------------------------------------
--Total Value vs Sold Value

SELECT SalePrice, TotalValue, (SalePrice - TotalValue) As Diff
From [Data-Cleaning].dbo.NashvilleHousing

-----------------------------------------------------------------------------------------------
--LandType Vs Total Value

SELECT LandUse, Avg(TotalValue) as AvgVal
From [Data-Cleaning].dbo.NashvilleHousing
Group by LandUse
Order by AvgVal Desc

-------------------------------------------------------------------------------------------------







  
