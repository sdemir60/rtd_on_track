import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/services/background_service.dart';

class ToggleTrackingUseCase {
  final BackgroundService backgroundService;

  ToggleTrackingUseCase(this.backgroundService);

  Future<Either<Failure, bool>> call(bool isTracking) async {
    try {
      if (isTracking) {
        await backgroundService.startService();
        return const Right(true);
      } else {
        await backgroundService.stopService();
        return const Right(false);
      }
    } catch (e) {
      return Left(ServiceFailure(message: e.toString()));
    }
  }
}
