/*
Covid 19 Data Exploration

Skills Used: Joins,CTE, Temp Tables, Window Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Select * 
From PortfolioProject..CovidDeaths
where continent is not null
order by 3,4

--Select Data that we are going to be starting with----

Select location,date,total_cases,new_cases,total_deaths,population
From PortfolioProject..CovidDeaths
where continent is not null
order by 1,2

--Total Cases vs Total Deaths
--Shows likelihood of dying if you contract covid in your country

Select location,date,total_cases,total_deaths, (CONVERT(float,total_deaths)/NULLIF(CONVERT(float,total_cases),0))*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where location like '%kingdom%'
and continent is not null
order by 1,2

--Total Cases Vs Population
--Shows what percentage of population infected with covid

Select location,date,population,total_cases,(CONVERT(float,total_cases)/NULLIF(CONVERT(float,population),0))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
order by 1,2

--Countries with highest infection rate compared to population

Select location,population,MAX(total_cases) as HighestinfectionCount,MAX((CONVERT(float,total_cases)/NULLIF(CONVERT(float,population),0))*100)as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Group by location,population
order by PercentPopulationInfected desc

--Countries with Highest Death Count Per Population

Select location,MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
where continent is not null
Group by Location
order by TotalDeathCount desc

--BREAKING THINGS BY CONTINENT

--Showing continents with the highest death count per population

Select continent,MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
where continent is not null
Group by continent
order by TotalDeathCount desc

--GLOBAL NUMBERS


Select date,SUM(cast(new_cases as int)) as total_cases, SUM(cast(new_deaths as int)) as total_deaths
From PortfolioProject..CovidDeaths
where continent is not null
Group by date
order by 1,2

--Total population vs vaccinations
--Shows percentage of population that has received at least one covid vaccine

Select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

--Using CTE to perform calculation on Partition By in previous query

With PopvsVac(Continent,Location,Date,Population,New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
Select *,(RollingPeopleVaccinated/Population)*100
From PopvsVac

--Using Temp Table to perform Calculation on partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table  #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into  #PercentPopulationVaccinated
Select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date

	Select *,(RollingPeopleVaccinated/Population)*100
From  #PercentPopulationVaccinated

--Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
