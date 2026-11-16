#import "utils.typ": *

#show: format-doc

#grid(
  columns: 2,
  column-gutter: 1cm,

  source(
    indent-size: 2,
    ````typ
    #import "@preview/utraw:0.0.1": *

    #show: uraw

    ```py
    def greeting():
        print("Hello to you!")
    ```
    ````,
  ),

  source(
    ````typ
    #import "@preview/utraw:0.0.1": *

    #uraw(
      ```py
      def greeting():
          print("Hello to you!")
      ```,
    )
    ````,
  ),
)

#set align(center)

#uraw(
  ```py
  def greeting():
      print("Hello to you!")
  ```,
)
