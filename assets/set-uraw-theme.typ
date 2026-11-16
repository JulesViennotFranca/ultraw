#import "../export/main.typ": *
#import "utils.typ": *

#show: format-doc

#grid(
  columns: 2,
  column-gutter: 1cm,
  align: bottom,

  source(
    indent-size: 2,
    ````typ
    #set-uraw(..themes.dark)

    ```py
    def greeting():
        print("Hello to you!")
    ```
    ````,
  ),

  [
    #show: uraw
    #set-uraw(..themes.dark)

    ```py
    def greeting():
        print("Hello to you!")
    ```
  ],
)
