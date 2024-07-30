-- Covid 19 Data Exploration 

-- Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

SET @@SESSION.SQL_MODE = 'STRICT_ALL_TABLES';

select *
from coviddeaths;

select *
from covidvaccinations;

-- Selecting data to be working with

select location, `date`, population, total_cases, new_cases, total_deaths
from coviddeaths;

-- Looking at Total Cases vs Total Deaths
-- Likelihood of death in countries when diagnosed with Covid

select location, `date`, total_cases, total_deaths, (total_deaths/total_cases)*100 AS percentage_death
from coviddeaths;

select location, `date`, total_cases, total_deaths, (total_deaths/total_cases)*100 AS percentage_death
from coviddeaths
where location like "%Emirates";

-- Looking at Total Cases Vs Population
-- Shows the percentage of population infected

select location, `date`, population, total_cases, (total_cases/population)*100 AS infection_rate
from coviddeaths
where location like "%Emirates";

-- Countries with Highest infection rate 

select location, population, MAX(total_cases), (MAX(total_cases)/population)*100 AS highest_infection_rate
from coviddeaths
group by location, population
order by highest_infection_rate DESC;

-- Countries with Highest Death Count

select location, MAX(cast(total_deaths as unsigned)) AS highest_death_count
from coviddeaths
where continent != '' -- Continents not accepted as nulls. Considering it as empty string
group by location
order by highest_death_count DESC;

-- BREAKING DOWN THINGS BY CONTINENT

-- Showing contintents with the highest death count per population

select continent, MAX(cast(total_deaths as unsigned)) as highest_death_count
from coviddeaths
where continent != ''
group by continent
order by highest_death_count DESC;

-- Global Numbers

select SUM(population), SUM(new_cases), SUM(total_cases), SUM(new_deaths), SUM(total_deaths), 
		(SUM(new_deaths)/SUM(new_cases))*100 as death_percentage
from coviddeaths;

-- Total Population vs Total Vaccination
-- Shows Rolling Percentage of Population that has recieved at least one Covid Vaccine (window function)

select dea.continent, dea.location, dea.`date`, dea.population,  vac.new_vaccinations
	, SUM(vac.new_vaccinations) OVER (partition by dea.location order by dea.location, dea.date) as rolling_vaccinated
from coviddeaths as dea
join covidvaccinations as vac
	on dea.location = vac.location
    and dea.`date` = vac.`date`
where dea.continent !='';

-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac as
(
select dea.continent, dea.location, dea.`date`, dea.population,  vac.new_vaccinations
	, SUM(vac.new_vaccinations) OVER (partition by dea.location order by dea.location, dea.date) as rolling_vaccinated
from coviddeaths as dea
join covidvaccinations as vac
	on dea.location = vac.location
    and dea.`date` = vac.`date`
where dea.continent !=''
)
select *, (rolling_vaccinated/population)*100 as percentage_vaccinated
from PopvsVac;

-- Performing the same as above using temp table

create temporary table temp_covid
(
continent varchar(50),
location varchar(50),
`date` varchar(50),
population int,
new_vaccinations varchar(50),
rolling_vaccinated int
);

insert into temp_covid
select dea.continent, dea.location, dea.`date`, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (partition by dea.location order by dea.location, dea.date) as rolling_vaccinated
from coviddeaths as dea
join covidvaccinations as vac
	on dea.location = vac.location
    and dea.`date` = vac.`date`
where dea.continent !='';

select *, (rolling_vaccinated/population)*100
from temp_covid;
