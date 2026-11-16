#import "../export/main.typ": *
#import "utils.typ": *

#show: format-doc

#grid(
  columns: 2,
  column-gutter: 1cm,
  align: bottom,

  [
    #highlights.remove((ldel: "*|", rdel: "|*"), (ldel: "*!", rdel: "!*"))
    #source(
      indent-size: 2,
      ````typ
      ```py
      def greeting(name: str):
          if *|len(name) > 0|* and *|name[0].isupper()|*:
              print("Hello to you, " + name)
          else:
              raise *!RuntimeError!*("Not a name.")
      ```

      The guard conditions are highlighted in yellow \
      and the raised error is highlighted in red.
      ````,
    )
    #highlights.add(highlights.base(), highlights.alert())
  ],

  [
    #show: uraw

    ```py
    def greeting(name: str):
        if *|len(name) > 0|* and *|name[0].isupper()|*:
            print("Hello to you, " + name)
        else:
            raise *!RuntimeError!*("Not a name.")
    ```

    The guard conditions are highlighted in yellow \
    and the raised error is highlighted in red.
  ],
)
