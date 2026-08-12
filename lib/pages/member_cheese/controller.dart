import 'package:CiliCili/http/loading_state.dart';
import 'package:CiliCili/http/member.dart';
import 'package:CiliCili/models_new/space/space_cheese/data.dart';
import 'package:CiliCili/models_new/space/space_cheese/item.dart';
import 'package:CiliCili/pages/common/common_list_controller.dart';

class MemberCheeseController
    extends CommonListController<SpaceCheeseData, SpaceCheeseItem> {
  MemberCheeseController(this.mid);

  final int mid;

  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  @override
  List<SpaceCheeseItem>? getDataList(SpaceCheeseData response) {
    isEnd = response.page?.next == false;
    return response.items;
  }

  @override
  Future<LoadingState<SpaceCheeseData>> customGetData() =>
      MemberHttp.spaceCheese(
        page: page,
        mid: mid,
      );
}
