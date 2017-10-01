module Article exposing (..)

import Date exposing (Date)

type alias Article =
  { uuid : String
  , title : String
  , content : String
  , tags : List String
  , date : Date
  }

-- empty : Article
-- empty =
--   Article "" "" "" []

isId : String -> Article -> Bool
isId id { uuid } =
  uuid == id
