# https://github.com/yaml/pyyaml 6.0.1
import yaml
from dataclasses import dataclass
from difflib import unified_diff


def load(filename: str):
    with open(filename) as f:
        return list(yaml.safe_load_all(f))


@dataclass(frozen=True)
class ObjectID:
    api_version: str
    kind: str
    namespace: str
    name: str

    @property
    def key_elems(self) -> list[str]:
        return [self.api_version, self.kind, self.namespace, self.name]

    @property
    def key(self) -> str:
        return "^".join(self.key_elems)

    @property
    def readable(self) -> str:
        return ">".join(self.key_elems)

    @staticmethod
    def sorted(ids: list["ObjectID"]) -> list["ObjectID"]:
        return sorted(ids, key=lambda x: x.key)

    @staticmethod
    def from_obj(obj) -> "ObjectID":
        return ObjectID(
            api_version=obj["apiVersion"],
            kind=obj["kind"],
            namespace=obj["metadata"].get("namespace", ""),
            name=obj["metadata"]["name"],
        )


class ObjectMap:
    def __init__(self, filename: str, map: dict[ObjectID, str]):
        self.filename = filename
        self.map = map

    @staticmethod
    def build(filename: str) -> "ObjectMap":
        d = {}
        for doc in load(filename):
            obj_id = ObjectID.from_obj(doc)
            if obj_id in d:
                raise Exception(f"Duplicated object: {obj_id.readable} in {filename}")
            d[obj_id] = yaml.dump(doc, sort_keys=True)
        return ObjectMap(filename, d)

    @property
    def keys(self) -> list[ObjectID]:
        return list(self.map.keys())

    def get(self, key: ObjectID) -> str:
        return self.map.get(key, "")


@dataclass
class Diff:
    left: ObjectMap
    right: ObjectMap

    def diff(self, n: int = 3):
        keys = ObjectID.sorted(list(set(self.left.keys + self.right.keys)))
        for key in keys:
            yield unified_diff(
                self.left.get(key).splitlines(keepends=True),
                self.right.get(key).splitlines(keepends=True),
                fromfile=f"{self.left.filename} {key.readable}",
                tofile=f"{self.right.filename} {key.readable}",
                n=n,
            )

    def diff_id(self, n: int = 3):
        yield unified_diff(
            [f"{x.readable}\n" for x in ObjectID.sorted(self.left.keys)],
            [f"{x.readable}\n" for x in ObjectID.sorted(self.right.keys)],
            fromfile=f"{self.left.filename}",
            tofile=f"{self.right.filename}",
            n=n,
        )


if __name__ == "__main__":
    import sys
    from argparse import ArgumentParser, RawDescriptionHelpFormatter

    parser = ArgumentParser(
        description="Diff by object",
        formatter_class=RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "data",
        metavar="FILE",
        type=str,
        nargs="+",
        help="Targets for comparison, 2 files.",
    )
    parser.add_argument("-I", "--id", action="store_true", help="Object id diff only.")
    parser.add_argument(
        "-C",
        "--context",
        action="store",
        type=int,
        default=3,
        help="Output lines of copied context.",
    )

    args = parser.parse_args()
    if len(args.data) != 2:
        print("Requires 2 files", file=sys.stderr)
        parser.exit(1)

    left = args.data[0]
    right = args.data[1]

    lmap = ObjectMap.build(left)
    rmap = ObjectMap.build(right)
    diff = Diff(left=lmap, right=rmap)

    result = diff.diff_id(n=args.context) if args.id else diff.diff(n=args.context)
    for x in result:
        sys.stdout.writelines(x)
