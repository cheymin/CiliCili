import 'package:CiliCili/http/loading_state.dart';
import 'package:CiliCili/http/user.dart';
import 'package:CiliCili/models_new/follow/data.dart';
import 'package:CiliCili/pages/follow_type/controller.dart';

class FollowedController extends FollowTypeController {
  @override
  Future<LoadingState<FollowData>> customGetData() =>
      UserHttp.followedUp(mid: mid, pn: page);
}
