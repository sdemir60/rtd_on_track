import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/services/background_service.dart';
import '../../core/services/preferences_service.dart';
import '../usecases/track_location_usecase.dart';

class ToggleTrackingUseCase {
  final BackgroundService backgroundService;
  final PreferencesService _preferencesService = PreferencesService();
  final TrackLocationUseCase _trackLocationUseCase;

  ToggleTrackingUseCase(this.backgroundService, this._trackLocationUseCase);

  Future<Either<Failure, bool>> call(bool isTracking) async {
    try {
      if (isTracking) {
        await backgroundService.startService(_trackLocationUseCase);
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