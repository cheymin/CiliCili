import 'package:CiliCili/http/loading_state.dart';
import 'package:CiliCili/http/member.dart';
import 'package:CiliCili/models_new/follow/data.dart';
import 'package:CiliCili/models_new/follow/list.dart';
import 'package:CiliCili/pages/common/search/common_search_controller.dart';

class FollowSearchController
    extends CommonSearchController<FollowData, FollowItemModel> {
  FollowSearchController(this.mid);
  final int mid;

  @override
  Future<LoadingState<FollowData>> customGetData() =>
      MemberHttp.getfollowSearch(
        mid: mid,
        ps: 20,
        pn: page,
        name: editController.value.text,
      );

  @override
  List<FollowItemModel>? getDataList(FollowData response) {
    return response.list;
  }
}
