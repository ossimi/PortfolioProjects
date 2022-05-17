SELECT * 
FROM CovidDeaths
WHERE continent <> ''
ORDER BY 3,4

--SELECT *
--FROM CovidVaccinations
--ORDER BY 3,4

--Select data that we are going to be using

SELECT Location, Date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent <> ''
ORDER BY 1,2

--Looking at Total Cases vs Total Deaths

SELECT Location, Date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE location LIKE '%states' 
	AND continent <> ''
ORDER BY 1,2

SELECT Location, Date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE location LIKE '%came%'
	AND continent <> ''
ORDER BY 1,2

--Looking at Total Cases vs Population
--Shows what percentage of population got Covid

SELECT Location, Date, population, total_cases,  (total_cases/population)*100 AS CasePercentage
FROM CovidDeaths
WHERE location LIKE '%luxe%'--Luxembourg
	AND continent <> '' 
ORDER BY 1,2

SELECT Location, Date, population, total_cases, (total_cases/population)*100 AS CasePercentage
FROM CovidDeaths
WHERE continent <> ''
--WHERE location LIKE '%states'
ORDER BY 1,2

--Looking at Countries with Highest Infection Rate compared to Population

SELECT Location, population, MAX(total_cases) HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE continent <> ''
--WHERE location LIKE '%states'
GROUP BY Location, population
ORDER BY PercentPopulationInfected DESC

--Looking at Countries with Highest Death Rate compared to Population

SELECT Location, MAX(CAST(total_deaths AS INT)) TotalDeathCount
FROM CovidDeaths
WHERE continent <> ''
--WHERE location LIKE '%states'
GROUP BY Location
ORDER BY TotalDeathCount DESC


--Highest Death Rate compared to Population by Continent

SELECT location, MAX(CAST(total_deaths AS INT)) TotalDeathCount
FROM CovidDeaths
WHERE continent = ''
	AND location NOT LIKE '%INCOME%'
	--AND location NOT LIKE '%INTERNA%'
GROUP BY location
ORDER BY TotalDeathCount DESC


--Showing the Continents with the highest death count per population

SELECT continent, MAX(CAST(total_deaths AS INT)) TotalDeathCount
FROM CovidDeaths
WHERE continent <> ''
	--AND location NOT LIKE '%INCOME%'
	--AND location NOT LIKE '%INTERNA%'
GROUP BY continent
ORDER BY TotalDeathCount DESC


--GLOBAL NUMBERS

SELECT 
	SUM(new_cases) AS total_cases, 
	SUM(CAST(new_deaths AS INT)) AS total_deaths, 
	SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent <> ''

--GLOBAL NUMBERS PER DATE

SELECT 
	Date, 
	SUM(new_cases) AS total_cases, 
	SUM(CAST(new_deaths AS INT)) AS total_deaths, 
	SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent <> ''
GROUP BY date
ORDER BY 1


-- Looking at total Population vs Vaccinations

SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION by dea.location ORDER BY dea.Location, dea.date) AS RollingPeopleVaccinated
	--SUM(CAST(vac.new_vaccinations AS INT)) OVER(PARTITION BY dea.location) not working (arithmetic overflow error converting expression to data type int)
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent <> ''
ORDER BY 2,3


--USE CTE

WITH PopvsVac (Continent, Location, Date, Population,New_Vaccinations, RollingPeopleVaccinated) 
AS
(
	SELECT 
		dea.continent, 
		dea.location, 
		dea.date, 
		dea.population,
		vac.new_vaccinations,
		SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION by dea.location ORDER BY dea.Location, dea.date) AS RollingPeopleVaccinated
	FROM CovidDeaths dea
	JOIN CovidVaccinations vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent <> ''
)
SELECT * , (RollingPeopleVaccinated/Population)*100
FROM PopvsVac


-- TEMP TABLE

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
	(
	Continent NVARCHAR(255),
	Location NVARCHAr(255),
	Date datetime,
	Population numeric,
	New_vaccinations bigint,
	RollingPeopleVaccinated numeric
	)

INSERT INTO #PercentPopulationVaccinated
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population,
	CAST(New_vaccinations AS bigint),
	SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION by dea.location ORDER BY dea.Location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent <> ''

SELECT * , (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated


--Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population,
	CAST(New_vaccinations AS bigint) AS new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION by dea.location ORDER BY dea.Location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent <> ''


SELECT *
FROM PercentPopulationVaccinated