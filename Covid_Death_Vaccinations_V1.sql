--SELECT * FROM PortfolioProjects..CovidDeaths


--SELECT * FROM PortfolioProjects..CovidDeaths
--ORDER BY 3,4

--SELECT * FROM PortfolioProjects..CovidVaccinations
--SELECT * FROM PortfolioProjects..CovidDeaths

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProjects..CovidDeaths
order by 1,2

-------------------------------------------------------------------------------------------------
--Total cases vs Total Deaths

--UPDATE PortfolioProjects..CovidDeaths
--SET total_deaths = TRY_CONVERT(BIGINT, total_deaths)

--UPDATE PortfolioProjects..CovidDeaths
--SET total_cases = TRY_CONVERT(BIGINT, total_cases)

--UPDATE PortfolioProjects..CovidDeaths
--SET total_cases = CAST(total_cases AS BIGINT)
--WHERE ISNUMERIC(total_cases) = 1

--Alter table PortfolioProjects..CovidDeaths alter column 

Alter TABLE PortfolioProjects..CovidDeaths
ALTER column total_cases FLOAT
GO

Alter TABLE PortfolioProjects..CovidDeaths
ALTER column total_deaths FLOAT
GO

--THIS IS TO COMPARE TOTAL DEATHS and TOTAL CASES
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProjects..CovidDeaths
WHERE location like '%India%'
order by 1,2
--Insights
--India was at peak death percentage in January of 2022 which was 1.38 481486 died
--India as of July 8 is 1.18 which isnt significant despite the vaccine mandate 531908 died

-------------------------------------------------------------------------------------------------
--Looking at Total Cases vs Population
--Shows what percentage of population got COVID
SELECT location, date, population, total_deaths, (total_deaths/population)*100 as PopulationDeathPercentage
FROM PortfolioProjects..CovidDeaths
WHERE location like 'China'
order by 1,2

--Insights
--As of February 2020 9.60103889272151E-05% of the population Died 
-- And it drastically went to 3 July 2023 is 0.0085203083643297%

-------------------------------------------------------------------------------------------------
-- Highest Infection Rate Compared to Population
SELECT location, population, MAX(total_cases) as HighestInfectionCount, Max(total_cases/population)*100 as InfectionPercentage
FROM PortfolioProjects..CovidDeaths
GROUP by location, population
ORDER BY InfectionPercentage DESC


--Insights
--Cyprus small population has 73 percentage of the population infected over the course of 3 years
--Yemen had the least Infection Count which was 0.03 percent about 11945 infected out of 33,696,612

-------------------------------------------------------------------------------------------------
--Showing Countries with Highest Death Count Per Population


SELECT location, MAX(total_deaths) as TotalDeathCount
FROM PortfolioProjects..CovidDeaths
WHERE continent is not NULL
GROUP BY location
order by TotalDeathCount DESC

--Insights
-- United States had the highest deathcount of 1127152
-- Nauru and Tuvalu are the two places with only 1 death count

-------------------------------------------------------------------------------------------------

SELECT *
FROM PortfolioProjects..CovidDeaths
WHERE location = 'Tuvalu'-- The place only has 11335 people there!

--BASED ON CONTINENTS

SELECT continent, MAX(total_deaths) as TotalDeathCount
FROM PortfolioProjects..CovidDeaths
WHERE continent is not NULL
GROUP BY continent
order by TotalDeathCount DESC

--Insights
-- North America are all United States and not canada

-------------------------------------------------------------------------------------------------

SELECT location, MAX(total_deaths) as TotalDeathCount
FROM PortfolioProjects..CovidDeaths
WHERE continent is NULL
GROUP BY location
order by TotalDeathCount DESC

--Weird Insight
--Theres High Income, Upper Middle Income and Lower middle income used in location which does not make sense

-------------------------------------------------------------------------------------------------

--Showing Continents with the Highest Death Count
SELECT continent, MAX(total_deaths) as TotalDeathCountContinentWise
FROM PortfolioProjects..CovidDeaths
WHERE continent is not NULL
Group by continent
ORDER BY TotalDeathCountContinentWise DESC

--Insight 
--Oceania Least Death and North America highest without canada
-------------------------------------------------------------------------------------------------

--GLOBAL NUMBERS

SELECT date,SUM(new_cases) as TotalCases,SUM(new_deaths)as TotalDeaths, Sum(new_deaths)/NULLIF(SUM(new_cases),0)*100 as GlobalDeathPercentage--(total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProjects..CovidDeaths
WHERE continent is not NULL
GROUP BY date
ORDER BY 1,2

--Insight
--The total cases perday are changing
--It is still very unstable

--now let's look at the death percentage across the world
SELECT SUM(new_cases) as TotalCases,SUM(new_deaths)as TotalDeaths, Sum(new_deaths)/NULLIF(SUM(new_cases),0)*100 as GlobalDeathPercentage--(total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProjects..CovidDeaths
WHERE continent is not NULL
--GROUP BY date
ORDER BY 1,2

--Insight
-- It is 0.905% Global Death Percentage!

-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
--Started USING COVID VACCINATIONS

SELECT * 
from PortfolioProjects..CovidDeaths DEA
JOIN PortfolioProjects..CovidVaccinations VAC
ON DEA.location = VAC.location
AND DEA.date = VAC.date

--Lookiing at this, it does a rolling count of how many people got vaccinated i.e new_vaccinations
--and adds to the rolling coount of people vaccinated, what does it do over?
--It does this over DEA.location of the place

SELECT DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations
,SUM(CAST(VAC.new_vaccinations as bigint)) OVER (Partition BY DEA.location ORDER BY DEA.location, DEA.date) as RollingCountPeopleVaccinated
from PortfolioProjects..CovidDeaths DEA
JOIN PortfolioProjects..CovidVaccinations VAC
ON DEA.location = VAC.location
AND DEA.date = VAC.date
WHERE DEA.continent is not NULL --and DEA.location <> 'High income' or DEA.location <> 'Low income' or DEA.location <> 'Lower middle income'
ORDER BY 2,3


--to find total population vs total count of people vaccinated
--However we can't use this new column hence we use the CTE

WITH PopvsVac(continent, location, date, population,new_vaccinations, RollingCountPeopleVaccinated)
AS 
(
SELECT DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations
,SUM(CAST(VAC.new_vaccinations as bigint)) OVER (Partition BY DEA.location ORDER BY DEA.location, DEA.date)
as RollingCountPeopleVaccinated
from PortfolioProjects..CovidDeaths DEA
JOIN PortfolioProjects..CovidVaccinations VAC
ON DEA.location = VAC.location
AND DEA.date = VAC.date
WHERE DEA.continent is not NULL --and DEA.location <> 'High income' or DEA.location <> 'Low income' or DEA.location <> 'Lower middle income'
--ORDER BY 2,3
)

SELECT *,(RollingCountPeopleVaccinated/population)*100 FROM PopvsVac as TotalVaccinatedPopulation
-------------------------------------------------------------------------------------------------
--USING TEMP TABLES!!

DROP TABLE if exists #PercentPopulationVaccinated
Create TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingCountPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
SELECT DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations
,SUM(CAST(VAC.new_vaccinations as numeric)) OVER (Partition BY DEA.location ORDER BY DEA.location, DEA.date)
as RollingCountPeopleVaccinated
from PortfolioProjects..CovidDeaths DEA
JOIN PortfolioProjects..CovidVaccinations VAC
ON DEA.location = VAC.location
AND DEA.date = VAC.date
WHERE DEA.continent is not NULL

SELECT *,(RollingCountPeopleVaccinated/population)*100 FROM #PercentPopulationVaccinated
as VaccinatedPopulationPercentage

-------------------------------------------------------------------------------------------------

--Creating View for Later Visualization

Create View PercentPopulationVaccinated as 
SELECT DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations
,SUM(CAST(VAC.new_vaccinations as numeric)) OVER (Partition BY DEA.location ORDER BY DEA.location, DEA.date)
as RollingCountPeopleVaccinated
from PortfolioProjects..CovidDeaths DEA
JOIN PortfolioProjects..CovidVaccinations VAC
ON DEA.location = VAC.location
AND DEA.date = VAC.date
WHERE DEA.continent is not NULL

Select * from PercentPopulationVaccinated