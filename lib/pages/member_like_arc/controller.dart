import 'package:CiliCili/http/loading_state.dart';
import 'package:CiliCili/http/member.dart';
import 'package:CiliCili/models_new/member/coin_like_arc/data.dart';
import 'package:CiliCili/models_new/member/coin_like_arc/item.dart';
import 'package:CiliCili/pages/common/common_list_controller.dart';

class MemberLikeArcController
    extends CommonListController<CoinLikeArcData, CoinLikeArcItem> {
  final dynamic mid;
  MemberLikeArcController({this.mid});

  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  @override
  List<CoinLikeArcItem>? getDataList(CoinLikeArcData response) {
    return response.item;
  }

  @override
  Future<LoadingState<CoinLikeArcData>> customGetData() =>
      MemberHttp.likeArc(mid: mid, page: page);
}
