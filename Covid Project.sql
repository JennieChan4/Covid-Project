-- Describe Table Structure
Describe covidvaccination;

-- Update Date Format in covidvaccination to align with coviddeaths 
Update covidvaccination
Set date = STR_TO_DATE(covidvaccination.date, "%e/%c/%Y")

-- Fill down to replace empty cell of Vaccinated Peole count
With VaccinationMetrics (continent, location, date, TotalVaccinated, TotalFullyVaccinated , Population) as
(Select vac.continent, vac.location, vac.date, 
MAX(CAST(vac.people_vaccinated as signed)) over (partition by vac.location 
ORDER BY date ASC ROWS UNBOUNDED PRECEDING) as TotalVaccinated,


MAX(CAST(vac.people_fully_vaccinated as signed)) over (partition by vac.location 
ORDER BY date ASC ROWS UNBOUNDED PRECEDING) as TotalFullyVaccinated,
death.Population
From covidvaccination as vac
Join coviddeaths as death 
ON death.location = vac.location 
AND death.date = vac.date
where vac.continent <> "" 
)
-- Time Trend of Vaccination Metrics
Select *, (TotalVaccinated/Population)*100 as VaccinatedPercentage,
(TotalFullyVaccinated/Population)*100 as FullyVaccinatedPercentage,
(TotalVaccinated - TotalFullyVaccinated) as PartiallyVaccinated,
((TotalVaccinated- TotalFullyVaccinated)/Population)*100 as PartiallyVaccinatedPercentage,
(Population - TotalVaccinated) as Unvaccinated, 
(Population - TotalVaccinated)/Population*100 as UnvaccinatedPercentage
From VaccinationMetrics
Order by location, date

-- Latest Vaccination Metrics in Hong Kong
With PercentageChangeVaccination 
(location, date, total_vaccinations, people_vaccinated, people_fully_vaccinated,
Lag_total_vaccinations, Lag_people_vaccinated, Lag_people_fully_vaccinated)
AS 
(
Select location, Date, total_vaccinations, people_vaccinated, people_fully_vaccinated,
lag(total_vaccinations,1) over (partition by location order by date) as Lag_total_vaccinations,
lag(people_vaccinated,1) over (partition by location order by date) as Lag_people_vaccinated,
lag(people_fully_vaccinated,1) over (partition by location order by date) as Lag_people_fully_vaccinated
from covidvaccination 
where location = 'Hong Kong'
)
-- Calculate the Percentage Change
Select date, location, total_vaccinations, people_vaccinated, people_fully_vaccinated,
(total_vaccinations-Lag_total_vaccinations)/Lag_total_vaccinations as DosePercentageChange,
(people_vaccinated-Lag_people_vaccinated)/Lag_people_vaccinated as PeopleVaccinatedPercentageChange,
(people_fully_vaccinated-Lag_people_fully_vaccinated)/Lag_people_fully_vaccinated as FullyVaccinatedPercentageChange
from PercentageChangeVaccination
where location = 'Hong Kong' 
AND Date = '2022-09-11'