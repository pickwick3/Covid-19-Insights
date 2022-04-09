-- Quick data inspection
SELECT * FROM CovidProject..covid_deaths
ORDER BY location, date

SELECT * FROM CovidProject..covid_vaccinations
ORDER BY location, date


-- Global numbers
SELECT
	SUM(new_cases) AS total_global_cases,
	SUM(CAST(new_deaths AS INT)) AS total_global_deaths,
	SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 AS total_global_death_percentage
FROM CovidProject..covid_deaths
WHERE covid_deaths.continent IS NOT NULL


-- Continents with highest death count
SELECT
	continent,
	SUM(CAST(new_deaths AS INT)) AS total_death_count
FROM CovidProject..covid_deaths
WHERE continent IS NOT NULL -- when continent is null, location/country becomes the continent
GROUP BY continent
ORDER BY total_death_count DESC


-- Countries with highest infection/infected percentage
SELECT
	location,
	population,
	MAX(total_cases) AS infection_count,
	MAX((total_cases / population * 100)) AS infected_percentage
FROM CovidProject..covid_deaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY infection_count DESC


-- Total population vs vaccinations
SELECT
	deaths.continent,
	deaths.location,
	deaths.date,
	deaths.population,
	vaxes.new_vaccinations,
	SUM(CAST(vaxes.new_vaccinations AS BIGINT)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS rolling_vax_count_by_location
FROM
	CovidProject..covid_deaths AS deaths
	JOIN CovidProject..covid_vaccinations AS vaxes
		ON deaths.location = vaxes.location
		AND deaths.date = vaxes.date
WHERE deaths.continent IS NOT NULL
ORDER BY location, date


-- Vax stats by country
WITH vaxed_population AS(
	SELECT
		deaths.location,
		deaths.date,
		deaths.population,
		vaxes.new_vaccinations,
		SUM(CAST(vaxes.new_vaccinations AS bigint)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS rolling_vax_count_by_location
	FROM
		CovidProject..covid_deaths AS deaths FULL OUTER JOIN CovidProject..covid_vaccinations AS vaxes
			ON deaths.location = vaxes.location
			AND deaths.date = vaxes.date
	WHERE
		deaths.continent is not null
)
SELECT
	location,
	CAST(date AS DATE) AS date,
	MAX(population) AS population,
	MAX(rolling_vax_count_by_location) AS vax_count,
	MAX(rolling_vax_count_by_location / population) AS vaxed_to_population_ratio
FROM vaxed_population
GROUP BY location, date
ORDER BY location, date ASC