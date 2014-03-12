# Ref: http://build.nimrod-lang.org/docs/rstgen.html

# Imports
import os, strtabs, times, strutils
import packages/docutils/rstgen,
    packages/docutils/rstast,
    packages/docutils/rst

when isMainModule:
    import marshal


# Types
type
    IView* = generic x
        render(x) is string
    BlogPost* = object
        content*, description*, title*, date*: string


# Procedures
template compile*(filename, content, pattern: string, body: stmt) {.immediate, dirty.} =
    ## Iterate through matching file pattern and execute body
    bind walkFiles, readFile

    # TODO: Add filesystem monitor for this directory?
    # TODO: Skip files which have not been modified since last time

    # Find all files & iterate through them
    for filename in walkFiles(pattern):

        # For each file, retrieve content & call body
        var content = readFile(filename)

        # Call input body
        body


proc parse_metadata(list: PRstNode, post: var BlogPost) =
    ## Retrieve metadata from input RST node
    for node in list.sons:
        var name, value = ""

        # Retrieve metadata from sons
        for field in node.sons:
            case field.kind:
            of rnFieldName:
                field.renderRstToRst(name)
            of rnFieldBody:
                field.renderRstToRst(value)
            else: discard

        # Check for matching metadata
        case name.toLower
        of "description":
            post.description = value
        of "date":
            post.date = value


proc denilify(value: var string) =
    if value == nil: value = ""


proc cat_sons(title: PRstNode, result: var string) =
    ## Concatenate the text of all of sons of the input node
    for node in title.sons:
        result &= node.text


proc open_post*(content: string): BlogPost =
    ## Parse a blog post from RST
    var hasToc = false
    var rst    = content.rstParse("", 0, 1, hasToc, {})

    # Initialize RST generator
    var gen: TRstGenerator
    gen.initRstGenerator(outHtml, defaultConfig(), "", {}, nil, nil)

    # TODO Extract useful nodes and generate HTML
    var generatedHTML = ""
    var parsedMetadata, parsedTitle = false

    for node in rst.sons:

        case node.kind:
        of rnHeadline:
            # If this is the first instance, parse title
            if not parsedTitle:
                result.title = ""
                node.cat_sons(result.title)
                parsedTitle = true
            else:
                # Append to result
                gen.renderRstToOut(node, generatedHTML)

        of rnFieldList:
            # If this is the first instance, parse metadata
            if not parsedMetadata:
                node.parse_metadata(result)
                parsedMetadata = true
            else:
                # Append to result
                gen.renderRstToOut(node, generatedHTML)

        else:
            # Append to result
            gen.renderRstToOut(node, generatedHTML)

    # Fill a blog post content
    result.content = generatedHTML
    denilify(result.description)
    denilify(result.title)
    denilify(result.date)


proc titleEncode*(value: string): string =
    value.replace(" ", "-")

proc titleDecode*(value: string): string =
    value.replace("-", " ")


# Tests
when isMainModule:

    import templates

    proc master(view: string): string = tmpli html"""
        <html>
            <style>
                body { background: #000; color: #FFF; }
            </style>
            <div id="content">$view</div>
        </html>
        """

    # Test RST to HTML
    var text = "sample.rst".readFile()
    var post = open_post(text)

    # compile filename, content, "*.rst":
    #     var html = rstToHtml(content)
    #     writefile filename.changeFileExt(".html"), master(html)


    # Test url encode / decode
    var decoded = "The Right Tool"
    var encoded = titleEncode(decoded)
    echo "Encoded: ", encoded
    assert titleDecode(encoded) == decoded