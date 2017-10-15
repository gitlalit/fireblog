port module Main exposing (..)

import Navigation exposing (Location)
import Html exposing (Html)
import Html.Attributes
import Html.Extra
import Update.Extra as Update
import Window
import Date exposing (Date)
import Task
import Json.Decode as Decode
import Article.Decoder

import Types exposing (..)
import Article
import Routing
import View.Home
import View.Article
import View.Contact
import View.Static.Header
import View.Static.Footer
import View.Static.NotFound
import View.Static.About

port requestPosts : String -> Cmd msg
port getPosts : (Decode.Value -> msg) -> Sub msg

main : Program Never Model Msg
main =
  Navigation.program (Navigation << NewLocation)
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch
    [ Window.resizes Resizes
    , getPosts GetPosts
    ]

init : Location -> (Model, Cmd Msg)
init location =
  { location = location
  , route = Routing.parseLocation location
  , articles = []
  , menuOpen = False
  , contactFields =
    { email = ""
    , message = ""
    }
  } ! [ Task.perform DateNow Date.now, requestPosts "myself" ]

update : Msg -> Model -> (Model, Cmd Msg)
update msg ({ menuOpen } as model) =
  case msg of
    Navigation navigation ->
      handleNavigation model navigation
    HamburgerMenu action ->
      handleHamburgerMenu model action
    Resizes { width } ->
      if width >= 736 then
        model
          |> closeMenu
          |> Update.identity
      else
        model ! []
    DateNow date ->
      model ! []
    ContactForm action ->
      handleContactForm model action
    GetPosts posts ->
      posts
        |> Decode.decodeValue Article.Decoder.decodePosts
        |> Result.withDefault []
        |> List.map Article.toUnifiedArticle
        |> setArticlesIn model
        |> Update.identity

handleNavigation : Model -> SpaNavigation -> (Model, Cmd Msg)
handleNavigation model navigation =
  case navigation of
    NewLocation location ->
      model
        |> setLocation location
        |> setRoute (Routing.parseLocation location)
        |> Update.identity
    ReloadHomePage ->
      model ! [ Navigation.newUrl "/" ]
    ChangePage url ->
      (closeMenu model) ! [ Navigation.newUrl url ]
    BackPage ->
      model ! [ Navigation.back 1 ]
    ForwardPage ->
      model ! [ Navigation.forward 1 ]

handleHamburgerMenu : Model -> MenuAction -> (Model, Cmd Msg)
handleHamburgerMenu model action =
  case action of
    ToggleMenu ->
      toggleMenu model ! []

handleContactForm : Model -> ContactAction -> (Model, Cmd Msg)
handleContactForm model contactAction =
  case contactAction of
    SendContactMail ->
      model ! []
    EmailInput email ->
      model
        |> setEmailContact email
        |> Update.identity
    MessageInput message ->
      model
        |> setMessageContact message
        |> Update.identity

view : Model -> Html Msg
view model =
  Html.div []
    [ View.Static.Header.view model
    , Html.div
      [ Html.Attributes.class "body" ]
      [ Html.img
        [ Html.Attributes.class "banner-photo"
        , Html.Attributes.src "/static/img/banner-photo.jpg"
        ]
        []
      , Html.div
        [ Html.Attributes.class "container" ]
        [ customView model ]
      ]
    , View.Static.Footer.view
    ]

customView : Model -> Html Msg
customView ({ route } as model) =
  case route of
    Home ->
      View.Home.view model
    About ->
      View.Static.About.view model
    Article id ->
      model
        |> getArticleById id
        |> Maybe.map View.Article.view
        |> Maybe.withDefault (View.Static.NotFound.view model)
    Archives ->
      Html.Extra.none
    Contact ->
      View.Contact.view model
    NotFound ->
      View.Static.NotFound.view model
