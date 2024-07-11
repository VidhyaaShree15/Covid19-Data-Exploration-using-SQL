--Covid 19 Data Exploration
--Skills Used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Datatypes

--Query:1
select *
from PortfolioProject..CovidDeaths
order by 3,4

------------------------------------------------------------------------------------
--Query:2 (selecting the Data that we are going to start with)
select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths
where continent is not null
order by 1,2

-------------------------------------------------------------------------------------

--Query:3 (Total cases vs Total Death showing likelihood of death rates of a particular country)
SELECT 
    Location, 
    date, 
    total_cases,
    total_deaths, 
    (CAST(total_deaths AS FLOAT) / CAST(total_cases AS FLOAT)) * 100 AS DeathPercentage
FROM 
    PortfolioProject..CovidDeaths
WHERE 
    location LIKE '%states%'
    AND continent IS NOT NULL 
ORDER BY 
    1, 2

----------------------------------------------------------------------------------------

--Query:4 (Total cases vs Population, showing what percentage of population infected with covid)
SELECT 
    Location, 
    date, 
    Population, 
    total_cases,  
    (total_cases/population)*100 AS PercentPopulationInfected
FROM 
    PortfolioProject..CovidDeaths
ORDER BY 
    1, 2

-----------------------------------------------------------------------------------------

--Query:5 (showing countries with Highest Infection Rate compared to population)
Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Group by Location, Population
order by PercentPopulationInfected desc

----------------------------------------------------------------------------------------

--Query:6 (showing countries with Highest Death count per Population)
Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null 
Group by Location
order by TotalDeathCount desc

-----------------------------------------------------------------------------------------

--Query:7 (showing Continents with the Highest Death count per Population)
Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null 
Group by continent
order by TotalDeathCount desc

------------------------------------------------------------------------------------------

--Query:8 (Global Numbers)
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null 
order by 1,2

--------------------------------------------------------------------------------------------

--Query:9 (Total Population vs Vaccinations, showing percentage of population that has received atleast one Covid Vaccine)
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (
        PARTITION BY dea.Location 
        ORDER BY dea.location, dea.Date
    ) AS RollingPeopleVaccinated
    --, (RollingPeopleVaccinated/population)*100
FROM 
    PortfolioProject..CovidDeaths dea
JOIN 
    PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL 
ORDER BY 
    2, 3

-----------------------------------------------------------------------------------------------

--Query:10 (Using CTE to perform calculation on partition by in previous query)
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) AS
(
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
    FROM 
        PortfolioProject..CovidDeaths dea
    JOIN 
        PortfolioProject..CovidVaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE 
        dea.continent IS NOT NULL 
)
SELECT *, (RollingPeopleVaccinated / Population) * 100 AS VaccinationPercentage
FROM PopvsVac

---------------------------------------------------------------------------------------------------

--Query:11 (Using Temp Table to perform calculation on partition by in previous query)
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

----------------------------------------------------------------------------------------------------
--Query:12 (Inserting data to PercentPopulationVaccinated)
INSERT INTO #PercentPopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (
        PARTITION BY dea.Location 
        ORDER BY dea.location, dea.Date
    ) AS RollingPeopleVaccinated
FROM 
    PortfolioProject..CovidDeaths dea
JOIN 
    PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date;

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-----------------------------------------------------------------------------------------------------
--Query:13 (creating view to store data for later visualizations)
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

-------------------------------------------------------------------------------------------------------







