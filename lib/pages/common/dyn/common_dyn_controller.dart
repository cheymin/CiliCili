import 'package:CiliCili/grpc/bilibili/main/community/reply/v1.pb.dart';
import 'package:CiliCili/grpc/reply.dart';
import 'package:CiliCili/http/loading_state.dart';
import 'package:CiliCili/pages/common/reply_controller.dart';
import 'package:CiliCili/pages/video/reply/vote/reply_vote_mixin.dart';
import 'package:CiliCili/utils/storage_pref.dart';
import 'package:get/get.dart';

abstract class CommonDynController extends ReplyController<MainListReply>
    with ReplyVoteMixin {
  int get oid;
  int get replyType;

  late final RxBool showTitle = false.obs;

  late final horizontalPreview = Pref.horizontalPreview;
  late final List<double> ratio = Pref.dynamicDetailRatio;

  late final showDynActionBar = Pref.showDynActionBar;

  @override
  Future<LoadingState<MainListReply>> customGetData() => ReplyGrpc.mainList(
    type: replyType,
    oid: oid,
    mode: mode,
    cursorNext: cursorNext,
    offset: paginationReply?.nextOffset,
  );

  @override
  List<ReplyInfo>? getDataList(MainListReply response) {
    return response.replies;
  }
}
