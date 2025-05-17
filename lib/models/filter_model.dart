class JobFilters {
  String? jobRole;
  String? location;
  String? applicationStatus;
  Set<String> companies;
  Set<String> jobTypes;

  JobFilters({
    this.jobRole,
    this.location,
    this.applicationStatus,
    Set<String>? companies,
    Set<String>? jobTypes,
  })  : companies = companies ?? {},
        jobTypes = jobTypes ?? {};
}
