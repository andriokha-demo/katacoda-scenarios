## Task

We're going to use the Eleventy base blog repository to get going quicker.

1. Clone the Eleventy base blog repository

   Clone the base blog repository into a local directory called `eleventy-blog`:

   `git clone https://github.com/11ty/eleventy-base-blog.git eleventy-blog`{{execute}}

1. Navigate to the directory

   `cd eleventy-blog`{{execute}}

   Specifically have a look at `eleventy-blog/.eleventy.js`{{open}} to see if you want to configure any Eleventy options differently.

1. Install dependencies

   `npm install`{{execute}}

1. Edit `eleventy-blog/_data/metadata.json`{{open}}

1. Run Eleventy

   This will build the site and start serving it - ie you will be able to browse to it. The command doesn't terminate
   automatically - it's waits for changes, rebuilds when it detects any, tells the browser to update, and then goes back
   to waiting. If you want to end the command you can press <kbd>Ctrl</kbd><kbd>C</kbd>.

   `npx eleventy --serve`{{execute}}

1. View the site at https://[[HOST_SUBDOMAIN]]-8080-[[KATACODA_HOST]].environments.katacoda.com/
   
   (If you're running locally just use the URL displayed when you ran `npx eleventy --serve`.) 

### Implementation Notes

* `about/index.md` shows how to add a content page.
* `posts/` has the blog posts but really they can live in any directory. They need only the `post` tag to be added to this collection.
* Add the `nav` tag to add a template to the top level site navigation. For example, this is in use on `index.njk` and `about/index.md`.
* Content can be any template format (blog posts needn’t be markdown, for example). Configure your supported templates in `.eleventy.js` -> `templateFormats`.
    * Because `css` and `png` are listed in `templateFormats` but are not supported template types, any files with these extensions will be copied without modification to the output (while keeping the same directory structure).
* The blog post feed template is in `feed/feed.njk`. This is also a good example of using a global data files in that it uses `_data/metadata.json`.
* This example uses three layouts:
    * `_includes/layouts/base.njk`: the top level HTML structure
    * `_includes/layouts/home.njk`: the home page template (wrapped into `base.njk`)
    * `_includes/layouts/post.njk`: the blog post template (wrapped into `base.njk`)
* `_includes/postlist.njk` is a Nunjucks include and is a reusable component used to display a list of all the posts. `index.njk` has an example of how to use it.
