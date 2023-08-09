SELECT *
FROM AviationData

SELECT *
FROM AviationFatalities


SELECT Eventdate, Country, PurposeofFlight, TotalfatalInjuries, TotalseriousInjuries,TotalMinorInjuries,TotalUninjured
FROM AviationFatalities
order by eventdate

SELECT Eventdate, Country, PurposeofFlight, TotalfatalInjuries, TotalseriousInjuries,TotalMinorInjuries,TotalUninjured,
isnull (TotalfatalInjuries, 0), isnull (TotalSeriousInjuries, 0), isnull (TotalMinorInjuries, 0), isnull (TotalUninjured, 0)
FROM PortfolioProject.dbo.AviationFatalities
order by eventdate

--Changing Null values to Zero

UPDATE PortfolioProject.dbo.AviationFatalities
SET TotalfatalInjuries = isnull (TotalfatalInjuries, 0),
TotalseriousInjuries = isnull (TotalSeriousInjuries, 0),
TotalMinorInjuries = isnull (TotalMinorInjuries, 0),
TotalUninjured = isnull (TotalUninjured, 0)
FROM PortfolioProject.dbo.AviationFatalities


SELECT Eventdate, Country, PurposeofFlight, TotalfatalInjuries, TotalseriousInjuries,TotalMinorInjuries,TotalUninjured
FROM AviationFatalities

order by eventdate

--Standardizing the Date format

SELECT Eventdate, Convert(Date,Eventdate)
FROM PortfolioProject.dbo.AviationFatalities

ALTER TABLE AviationFatalities
Add EventDateConverted Date;


Update AviationFatalities
set EventDateConverted = Convert(Date,Eventdate)

Update AviationFatalities
set Eventdate = EventDateConverted

--Evaluating Total Passengers in each flight

ALTER TABLE AviationFatalities
Add TotalPassengers int;

Update AviationFatalities
set TotalPassengers = TotalfatalInjuries + TotalseriousInjuries +TotalMinorInjuries+TotalUninjured

SELECT EventDateConverted, Country, PurposeofFlight, TotalfatalInjuries, TotalseriousInjuries,
TotalMinorInjuries, TotalUninjured, TotalPassengers
FROM AviationFatalities
order by eventdate

--Looking at cases where Injuries were not recorded
SELECT EventDateConverted, Country, PurposeofFlight, TotalfatalInjuries, TotalseriousInjuries,
TotalMinorInjuries, TotalUninjured, TotalPassengers
FROM AviationFatalities
WHERE TotalPassengers = 0
order by eventdate

--Evaluating Percentage of Fatality in each flight and streamlining to Nigeria

SELECT EventDateConverted, Country, PurposeofFlight, TotalfatalInjuries, TotalPassengers, 
(TotalfatalInjuries/NULLIF(TotalPassengers,0)*100) as PercentFatality
FROM AviationFatalities
--WHERE COUNTRY = 'Nigeria'
order by eventdate


--Countries with highest numberof accidents

SELECT Country, COUNT(EventId) as Numberofaccidents
FROM AviationFatalities
Group by  Country
Order by Numberofaccidents desc

--Countries with the largest percent fatality

With PercFat (EventDateConverted, Country, PurposeofFlight, TotalfatalInjuries, TotalPassengers, PercentFatality)
as
(
SELECT EventDateConverted, Country, PurposeofFlight, TotalfatalInjuries, TotalPassengers, 
(TotalfatalInjuries/NULLIF(TotalPassengers,0)*100) as PercentFatality
FROM AviationFatalities
--WHERE COUNTRY = 'Nigeria'
)

SELECT Country, Max(PercentFatality)
FROM PercFat
GROUP BY Country
ORDER BY Max(PercentFatality) desc

--Phase of flight when accident occured

SELECT  isnull(Broadphaseofflight,'Unknown') as PhaseofFlight ,COUNT(EventId) as Numberofaccidents
FROM AviationFatalities
Group by  Broadphaseofflight
Order by Numberofaccidents desc

--Purpose of flight by number of accidents

SELECT Purposeofflight, COUNT(EventId) as Numberofaccidents
FROM AviationFatalities
Where Purposeofflight is not null
Group by  Purposeofflight
Order by Numberofaccidents desc


--Number of accidents per year from 2000 to 2022
SELECT  Year(EventDate) as AccidentYear, COUNT(EventId) as Numberofaccidents
FROM AviationFatalities
Group by Year(EventDate)
Having Year(EventDate) > 2000
Order by Numberofaccidents desc

--Extent of Aircraft damage and fatality

SELECT Info.Aircraftdamage, sum(Fat.TotalfatalInjuries) as FatalInjuries, COUNT(fat.EventId) as Numberofaccidents
FROM AviationFatalities Fat
JOIN AviationData Info
	on Fat.EventId = Info.EventId
	and fat.AccidentNumber = Info.AccidentNumber
where Info.Aircraftdamage is not null
Group by Info.Aircraftdamage
Order by 2 desc




--Looking at the Causes of Accidents
With CrashCause (NumberofAccidents, reportstatus, NumAcc, Probablecause) as
(
SELECT count(EVENTID), ReportStatus, count(EventId),
Case when ReportStatus LIKE '%Pilot error%' then 'Pilot error'
	 when ReportStatus LIKE '%weather%' then  'Windcaused' 
	 when ReportStatus LIKE '%Bird%' then 'Bird/Wildlifecaused' 
	 when ReportStatus LIKE '%Engine%' then 'Engine Failure'	
	 when ReportStatus LIKE '%Control%' then 'Loss of control'
	 when ReportStatus LIKE '%Probable cause%' then 'Unidentified'
	 else  'Other causes'
End as Probablecause
FROM AviationFatalities
WHERE ReportStatus is NOT null
Group by reportstatus)

SELECT Probablecause, Sum(NumberofAccidents) as Numberofaccidents, CONVERT(DECIMAL(5,2),sum(cast(NumberofAccidents as float)/88889)*100) as Percentage
FROM Crashcause
group by Probablecause
Order by NumberofAccidents


--TEMP TABLE
DROP TABLE IF EXISTS #AviationAccidents
CREATE TABLE #AviationAccidents
(
EventDateConverted DATE, 
Country nvarchar (255),
Location nvarchar (255),
PurposeofFlight nvarchar (255), 
Aircraftdamage nvarchar (255), 
TotalfatalInjuries int, 
TotalseriousInjuries int,
TotalMinorInjuries int,
TotalUninjured int,
TotalPassengers int
)
Insert into #AviationAccidents
SELECT fat.EventDateConverted, fat.Country, info.Location, fat.PurposeofFlight, info.Aircraftdamage, 
	   fat.TotalfatalInjuries, fat.TotalseriousInjuries,fat.TotalMinorInjuries,fat.TotalUninjured, fat.TotalPassengers
FROM AviationFatalities Fat
JOIN AviationData Info
	on Fat.EventId = Info.EventId
	and fat.AccidentNumber = Info.AccidentNumber
WHERE info.EventId is not null
--order by info.EventDate

SELECT *
FROM #AviationAccidents


--Creating a view of data to be used later
CREATE VIEW AviationCases as
SELECT fat.EventDateConverted, fat.Country, info.Location, fat.PurposeofFlight, info.Aircraftdamage, 
	   fat.TotalfatalInjuries, fat.TotalseriousInjuries,fat.TotalMinorInjuries,fat.TotalUninjured, fat.TotalPassengers
FROM AviationFatalities Fat
JOIN AviationData Info
	on Fat.EventId = Info.EventId
	and fat.AccidentNumber = Info.AccidentNumber
WHERE info.EventId is not null