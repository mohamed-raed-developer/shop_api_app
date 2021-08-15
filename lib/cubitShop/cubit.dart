import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shop_api_app/cubitShop/states.dart';
import 'package:shop_api_app/models/categories_model.dart';
import 'package:shop_api_app/models/change_favorites_model.dart';
import 'package:shop_api_app/models/favorites_model.dart';
import 'package:shop_api_app/models/home_model.dart';
import 'package:shop_api_app/models/login_model.dart';
import 'package:shop_api_app/screens/appScreens/categories_screen.dart';
import 'package:shop_api_app/screens/appScreens/favorites_screen.dart';
import 'package:shop_api_app/screens/appScreens/products_screen.dart';
import 'package:shop_api_app/screens/appScreens/settings_screen.dart';
import 'package:shop_api_app/shared/cache_helper.dart';
import 'package:shop_api_app/shared/dio_helper.dart';
import 'package:shop_api_app/shared/end_points.dart';
import 'package:shop_api_app/widgets/constant.dart';

class ShopCubit extends Cubit<ShopStates> {
  ShopCubit() : super(ShopInitialState());

  static ShopCubit get(context) => BlocProvider.of(context);

  int currentIndex = 0;

  List<Widget> bottomScreens = [
    ProductsScreen(),
    CategoriesScreen(),
    FavoritesScreen(),
    SettingsScreen(),
  ];

  void changeBottom(int index) {
    currentIndex = index;
    emit(ShopChangeBottomNavState());
  }

  HomeModel homeModel;
  Map<int, bool> favorites = {};

  void getHomeData() {
    emit(ShopLoadingHomeDataState());
    DioHelper.getData(
      url: HOME,
      token: token,
    ).then((value) {
      homeModel = HomeModel.fromJson(value.data);

      // printFullText(homeModel.data.banners[0].image);
      // print(homeModel.status);
      homeModel.data.products.forEach((element) {
        favorites.addAll({
          element.id: element.inFavorites,
        });
      });
      print(favorites.toString());
      emit(ShopSuccesHomeDataState());
    }).catchError((error) {
      emit(ShopErrorHomeDataState());
      print(error.toString());
    });
  }

  CategoriesModel categoriesModel;
  void getCategories() {
    DioHelper.getData(
      url: GET_CATEGORIES,
      token: token,
    ).then((value) {
      categoriesModel = CategoriesModel.fromJson(value.data);

      emit(ShopSuccesCategoriesState());
    }).catchError((error) {
      emit(ShopErrorCategoriesState());
      print(error.toString());
    });
  }

  ChangeFavoritesModel changeFavoritesModel;
  void changeFavorites(int productId) {
    favorites[productId] = !favorites[productId];
    emit(ShopChangeFavoritesState());
    DioHelper.postData(
      url: FAVORITES,
      data: {
        'product_id': productId,
      },
      token: token,
    ).then((value) {
      changeFavoritesModel = ChangeFavoritesModel.fromJson(value.data);
      print(value.data);
      if (!changeFavoritesModel.status) {
        favorites[productId] = !favorites[productId];
      } else {
        getFavorites();
      }
      emit(ShopSuccesChangeFavoritesState(changeFavoritesModel));
    }).catchError((error) {
      favorites[productId] = !favorites[productId];
      emit(ShopErrorChangeFavoritesState());
    });
  }

  FavoritesModel favoritesModel;
  void getFavorites() {
    emit(ShopLoadingGetFavoritesState());
    DioHelper.getData(
      url: FAVORITES,
      token: token,
    ).then((value) {
      favoritesModel = FavoritesModel.fromJson(value.data);
      // printFullText(value.data.toString());
      emit(ShopSuccesGetFavoritesState());
    }).catchError((error) {
      emit(ShopErrorGetFavoritesState());
      print(error.toString());
    });
  }

  ShopLoginModel userModel;
  void getUserData() {
    emit(ShopLoadingUserDataState());
    DioHelper.getData(
      url: PROFILE,
      token: token,
    ).then((value) {
      userModel = ShopLoginModel.fromJson(value.data);
      printFullText(userModel.data.name);
      emit(ShopSuccesUserDataState(userModel));
    }).catchError((error) {
      emit(ShopErrorUserDataState());
      print(error.toString());
    });
  }

  void updateUserData({
    @required String name,
    @required String email,
    @required String phone,
  }) {
    emit(ShopLoadingUpdateUserDataState());
    DioHelper.putData(
      url: UPDATE_PROFILE,
      token: token,
      data: {
        'name': name,
        'email': email,
        'phone': phone,
      },
    ).then((value) {
      userModel = ShopLoginModel.fromJson(value.data);
      printFullText(userModel.data.name);
      emit(ShopSuccesUpdateUserDataState(userModel));
    }).catchError((error) {
      emit(ShopErrorUpdateUserDataState());
      print(error.toString());
    });
  }

  bool isDark = false;

  void changeAppMode({bool sharedDark}) {
    if (sharedDark != null) {
      isDark = sharedDark;
      emit(NewsChangeModeState());
    } else {
      isDark = !isDark;
      CacheHelper.putData(key: 'isDark', value: isDark).then((value) {
        emit(NewsChangeModeState());
      });
    }
  }
}
