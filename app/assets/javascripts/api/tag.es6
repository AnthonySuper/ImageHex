class Tag{
  constructor(json){
    for(var prop in json){
      this[prop] = json[prop];
    }
  }
  images(){
    return new ImageCollection('/tags/' + this.id, 'images');
  }
  static find(id, callback){
    $.getJSON("/tags/" + id, (t) => {
      callback(new Tag(t));
    });
  }
  /**
   * Get all tags with a prefix
   * @param{String} prefix the prefix
   * @param{Function} callback called with the array of tags
   */
  static withPrefix(prefix, callback){
    $.getJSON("/tags/suggest/"+ $.param({name: prefix}), (d) => {
      a = [];
      for(var t of d){
        a.push(new Tag(t));
      }
      callback(a);
    });
  }
}
