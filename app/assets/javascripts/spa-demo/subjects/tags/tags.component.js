(function() {
  'use strict';

  angular.module("spa-demo.subjects")
    .component("sdTagList", {
      templateUrl: tagListHtml,
      controller: tagListController,
    });

  tagListHtml.$inject = ["spa-demo.config.APP_CONFIG"];
  function tagListHtml(APP_CONFIG) {
    return APP_CONFIG.tag_list_html;
  }

  tagListController.$inject = ["$q", "spa-demo.subjects.Tag"];
  function tagListController($q, Tag) {
    var vm = this;
    vm.taglist = [];
    Tag.query().$promise.then(function(x, d) {
      vm.taglist = x;
    })
  }

  angular.module("spa-demo.subjects")
    .component("sdTagForm", {
      templateUrl: tagFormHtml,
      controller: tagFormController
    })

  tagFormHtml.$inject = ["spa-demo.config.APP_CONFIG"];
  function tagFormHtml(APP_CONFIG) {
    return APP_CONFIG.tag_form_html;
  }

  tagFormController.$inject = ["$scope", "$state", "spa-demo.subjects.Tag", "spa-demo.subjects.TagsAuthz"];
  function tagFormController($scope, $state, Tag, TagsAuthz) {
    var vm = this;
    vm.authz = TagsAuthz;
    vm.newTagName = "";
    vm.create = create;


    ///////////////////
    function create() {
      var tag = new Tag({name: vm.newTagName});
      tag.$save().then(
        function() {
          console.log("tag created");
          $state.reload();
        },
        function(e) {
          console.log(e)
        }
      );
    }
  }

  angular.module("spa-demo.subjects")
    .component("sdTagBox", {
      templateUrl: tagBoxHtml,
      controller: tagBoxController,
      bindings: {
        tag: "<"
      }
    })

  tagBoxHtml.$inject = ["spa-demo.config.APP_CONFIG"];
  function tagBoxHtml(APP_CONFIG) {
    return APP_CONFIG.tag_box_html;
  }

  tagBoxController.$inject = [
    "$scope",
    "$state",
    "spa-demo.subjects.Tag",
    "spa-demo.subjects.TagsAuthz",
    "spa-demo.subjects.ThingsAuthz"
  ];
  function tagBoxController($scope, $state, Tag, TagsAuthz, ThingsAuthz) {
    var vm = this;
    vm.authz = TagsAuthz;
    vm.thingsAuthz = ThingsAuthz;
    vm.newTagName = "";
    vm.things = [];
    vm.linkableThings = [];
    vm.selectedThing = null;

    vm.remove = remove;
    vm.update = update;
    vm.addToCategory = addToCategory;

    activate();
    return;
    ////////////////////
    function activate() {
      // Get things associated to this category
      Tag.associated_things({id: vm.tag.id}).$promise.then(function(x) {
        vm.things = x;
      });
      // Get things that user can associate to this category
      $scope.$watch(
        function() {
          return vm.authz.canGetLinkables()
        },
        function() {
          if (vm.authz.canGetLinkables()) {
            Tag.linkable_things({id: vm.tag.id}).$promise.then(function(x) {
              vm.linkableThings = x;
            })
          } else {
            vm.linkableThings = [];
          }
        }
      );

    }

    function update() {
      var oldName = vm.tag.name;
      vm.tag.name = vm.newTagName;
      vm.tag.$update().then(function(x) {
        console.log("New tag name saved");
        vm.newTagName = "";
      }).catch(
        function(e) {
          console.log(e);
          vm.tag.name = oldName;
        }
      );
    }

    function remove() {
      vm.tag.$remove().then(function(x) {
        $state.reload();
      }).catch(function(e) {
        console.log(e);
      })
    }

    function addToCategory() {
      Tag.associate_things({id:vm.tag.id, thing_id:vm.selectedThing}).$promise.then(function(x) {
        activate();
        vm.selectedThing = null;
      }).catch(function(e) {
        console.log(e);
      });
    }

  }
}());
