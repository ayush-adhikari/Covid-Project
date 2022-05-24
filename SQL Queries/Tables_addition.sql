select *
	from Portfolio_Project..Covid_deaths
	order by 3, 4;

-- Printing required data

Select location, date, total_cases, new_cases, total_deaths, population
	from Portfolio_Project..Covid_deaths
	where continent is not null
	order by 1, 2;

--Total cases vs total deaths
-- shows likelihood of a person dying due to CoronaVirus in India

Select location, date, total_cases, total_deaths,(total_deaths/total_cases)*100 as 'death_percentage'
	from Portfolio_Project..Covid_deaths
	where location = 'India' and continent is not null
	order by 1, 2;

----------------------------------------------------------------------------------------------------------

--Total cases vs Population
-- shows likelihood of a person contracting CoronaVirus in India

Select location, date, population, total_cases, (total_cases/population)*100 as 'contraction_percentage'
	from Portfolio_Project..Covid_deaths
	where location = 'India' and continent is not null
	order by 1, 2;

----------------------------------------------------------------------------------------------------------

--Countries with highest infection rate compared to population.

Select location, population, max(total_cases) as max_total_cases, max((total_cases/population)*100) as 'contraction_percentage'
	from Portfolio_Project..Covid_deaths
	where continent is not null
	group by location, population
	order by contraction_percentage desc;

----------------------------------------------------------------------------------------------------------

--Countries with highest death rate compared to population.

Select location, population, max(cast(total_deaths as int)) as max_total_deaths, max((cast(total_deaths as int)/population)*100) as 'death_percentage'
	from Portfolio_Project..Covid_deaths
	where continent is not null
	group by location, population
	order by death_percentage desc; 

----------------------------------------------------------------------------------------------------------

--Continents with highest death rate compared to population.

Select continent, max(cast(total_deaths as int)) as max_total_deaths, max((cast(total_deaths as int)/population)*100) as 'death_percentage'
	from Portfolio_Project..Covid_deaths
	where continent is not null 
	group by continent
	order by death_percentage desc; 

	----------------------------------------------------------------------------------------------------------

-- total corona cases, total corona deaths and percentage of people contracting corona dying per day
Select date, SUM(new_cases) as total_new_cases,
			SUM(cast(new_deaths as int)) as total_new_deaths,
			SUM(cast(new_deaths as int))/SUM(new_cases)*100 as death_percentage
	from Portfolio_Project..Covid_deaths
	where continent is not null
	group by date
	order by date;

----------------------------------------------------------------------------------------------------------

-- total populations vs New Vaccinations
with cte as ( 
	select death.continent, death.location, death.date, death.population, vacc.new_vaccinations,
			SUM(cast(vacc.new_vaccinations as bigint)) over(partition by death.location
			order by death.location, death.date) as rolling_vacc
		from Portfolio_Project..Covid_deaths death
		join Portfolio_Project..Covid_vaccinations vacc
			on death.location = vacc.location and death.date = vacc.date
			where death.continent is not null
)
select *, (rolling_vacc/population)*100 as rolling_vacc_perc
	from cte
	order by continent, location, date;

----------------------------------------------------------------------------------------------------------

-- total populations vs New Tests

with cte as ( 
	select death.continent, death.location, death.date, death.population, vacc.new_tests,
			SUM(cast(vacc.new_tests as bigint)) over(partition by death.location
			order by death.location, death.date) as rolling_tests
		from Portfolio_Project..Covid_deaths death
		join Portfolio_Project..Covid_vaccinations vacc
			on death.location = vacc.location and death.date = vacc.date
			where death.continent is not null
)
select *, (rolling_tests/population)*100 as rolling_tests_perc
	from cte
	order by continent, location, date;

----------------------------------------------------------------------------------------------------------

-- Creating views to store data for later visualisations

-- death count per continent.

drop view if exists Continent_death_count
create view Continent_death_count as 
	Select continent, max(cast(total_deaths as int)) as max_total_deaths, max((cast(total_deaths as int)/population)*100) as 'death_percentage'
		from Portfolio_Project..Covid_deaths
		where continent is not null and total_deaths is not null
		group by continent;
		--order by death_percentage desc;

----------------------------------------------------------------------------------------------------------

-- No of tests per Country
drop view if exists Country_test_rate
create view Country_test_rate as 
	Select location, max(cast(total_tests as bigint)) as max_total_tests, max((cast(total_tests as bigint)/population)*100) as 'tests_percentage'
		from Portfolio_Project..Covid_vaccinations
		where continent is not null and total_tests is not null
		group by location;
		--order by location;

----------------------------------------------------------------------------------------------------------

-- Positivity Rate per Country
drop view if exists Country_positivity_rate
create view Country_positivity_rate as 
	Select location, max(cast(positive_rate as float)) as max_positive_rate
		from Portfolio_Project..Covid_vaccinations
		where continent is not null and positive_rate is not null
		group by location
		--order by location;

----------------------------------------------------------------------------------------------------------

-- Number of tests vs population of the country.
drop view if exists population_vs_tests
create view population_vs_tests as 
	with cte as ( 
	select death.continent, death.location, death.date, death.population, vacc.new_tests,
			SUM(cast(vacc.new_tests as bigint)) over(partition by death.location
			order by death.location, death.date) as rolling_tests
		from Portfolio_Project..Covid_deaths death
		join Portfolio_Project..Covid_vaccinations vacc
			on death.location = vacc.location and death.date = vacc.date
			where death.continent is not null
	)
	select *, (rolling_tests/population)*100 as rolling_tests_perc
		from cte;
		--order by continent, location, date;

-- updating the tests' values to 0 where they are null
update population_vs_tests
	set new_tests = 0
	where new_tests is null;

----------------------------------------------------------------------------------------------------------

-- Positivity Rate per Country
drop view if exists population_vs_newVaccinnation
create view population_vs_newVaccinnation as 
	with cte as ( 
	select death.continent, death.location, death.date, death.population, vacc.new_vaccinations,
			SUM(cast(vacc.new_vaccinations as bigint)) over(partition by death.location
			order by death.location, death.date) as rolling_vacc
		from Portfolio_Project..Covid_deaths death
		join Portfolio_Project..Covid_vaccinations vacc
			on death.location = vacc.location and death.date = vacc.date
			where death.continent is not null
	)
	select *, (rolling_vacc/population)*100 as rolling_vacc_perc
		from cte;

-- updating the vaccinations' values to 0 where they are null
update population_vs_newVaccinnation
	set new_vaccinations = 0
	where new_vaccinations is null;

----------------------------------------------------------------------------------------------------------

update Portfolio_Project..Covid_vaccinations
	set total_vaccinations = 0
	where total_vaccinations is null;


select location as 'country', max(cast(people_vaccinated as bigint)) as 'people_vaccinated'
	from Portfolio_Project..Covid_vaccinations
	where location = 'India'
	group by location
	order by location;

select location as 'country', max(cast(total_vaccinations as bigint)) as 'total vaccinations'
	from Portfolio_Project..Covid_vaccinations
	where location = 'India'
	group by location
	order by location;