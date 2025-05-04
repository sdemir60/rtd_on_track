abstract class Failure {
  final String message;

  const Failure({required this.message});
}

class LocationFailure extends Failure {
  const LocationFailure({required super.message});
}

class DatabaseFailure extends Failure {
  const DatabaseFailure({required super.message});
}

class PermissionFailure extends Failure {
  const PermissionFailure({required super.message});
}

class ServiceFailure extends Failure {
  const ServiceFailure({required super.message});
}
