--Select Data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent is not null
ORDER BY 1,2

--Looking at total cases x total deaths
--Shows likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE location like '%brazil%'
AND continent is not null
ORDER BY 1,2


--Looking at the total cases vs Population
--Shows what percentage of population got Covid
SELECT location, date, total_cases, population, (total_cases/population) * 100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE location like '%brazil%'
AND continent is not null
ORDER BY 1,2

--Looking at countries with highest infection rate compared to population
SELECT location, population, max(total_cases) as HighestInfectionCount, (max(total_cases)/population) * 100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY PercentPopulationInfected desc

--Showing countries with highest death count per population
SELECT location, max(cast(total_deaths as int)) as TotalDeathCount
FROM CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount desc

--BY CONTINENT

--Showing continents with the highest count per popuplation
SELECT continent, max(cast(total_deaths as int)) as TotalDeathCount
FROM CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount desc

--Global numbers

SELECT sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, 
		(sum(cast(new_deaths as int)) / sum(new_cases)) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE continent is not null
ORDER BY 1,2

--Looking at Total Population vs Vaccinations
SELECT covd.continent, covd.location, covd.date, covd.population, covv.new_vaccinations,
SUM(CAST(new_vaccinations as int)) OVER (PARTITION BY covd.location ORDER BY covd.location, covd.date) as RollingPeopleVaccinated
FROM CovidDeaths covd
JOIN CovidVaccinations covv on covv.location = covd.location and covv.date = covd.date
ORDER BY 2,3

--CTE
WITH PopVsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT covd.continent, covd.location, covd.date, covd.population, covv.new_vaccinations,
SUM(CAST(new_vaccinations as int)) OVER (PARTITION BY covd.location ORDER BY covd.location, covd.date) as RollingPeopleVaccinated
FROM CovidDeaths covd
JOIN CovidVaccinations covv on covv.location = covd.location and covv.date = covd.date
WHERE covd.continent is not null
)
SELECT *, (RollingPeopleVaccinated/Population) * 100 
FROM PopVsVac
ORDER BY 2,3

--TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated

CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime, 
Population numeric,
new_vaccinations numeric,
rollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT covd.continent, covd.location, covd.date, covd.population, covv.new_vaccinations,
SUM(CAST(new_vaccinations as int)) OVER (PARTITION BY covd.location ORDER BY covd.location, covd.date) as RollingPeopleVaccinated
FROM CovidDeaths covd
JOIN CovidVaccinations covv on covv.location = covd.location and covv.date = covd.date
WHERE covd.continent is not null

SELECT * FROM #PercentPopulationVaccinated
ORDER BY 2,3


--Creating VIEW to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated as
SELECT covd.continent, covd.location, covd.date, covd.population, covv.new_vaccinations,
SUM(CAST(new_vaccinations as int)) OVER (PARTITION BY covd.location ORDER BY covd.location, covd.date) as RollingPeopleVaccinated
FROM CovidDeaths covd
JOIN CovidVaccinations covv on covv.location = covd.location and covv.date = covd.date
WHERE covd.continent is not null