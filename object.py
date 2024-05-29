# https://github.com/yaml/pyyaml 6.0.1
import yaml
from dataclasses import dataclass
from difflib import unified_diff


@dataclass
class ObjectID:
    api_version: str
    kind: str
    namespace: str
    name: str

    def __str__(self) -> str:
        return "^".join([self.api_version, self.kind, self.namespace, self.name])


def load(filename: str):
    with open(filename) as f:
        return list(yaml.safe_load_all(f))


def object2id(obj) -> ObjectID:
    return ObjectID(
        api_version=obj["apiVersion"],
        kind=obj["kind"],
        namespace=obj["metadata"].get("namespace", ""),
        name=obj["metadata"]["name"],
    )


class ObjectMap:
    def __init__(self, filename: str, map: dict[str, str]):
        self.filename = filename
        self.map = map

    @staticmethod
    def build(filename: str) -> "ObjectMap":
        d = {}
        for doc in load(filename):
            obj_id = object2id(doc)
            d[str(obj_id)] = yaml.dump(doc)
        return ObjectMap(filename, d)

    def keys(self) -> list[str]:
        return sorted(list(self.map.keys()))

    def get(self, key: str) -> str:
        return self.map.get(key, "")


def diff(left: ObjectMap, right: ObjectMap, n: int = 3):
    keys = sorted(list(set(left.keys() + right.keys())))
    for key in keys:
        l = left.get(key).splitlines(keepends=True)
        r = right.get(key).splitlines(keepends=True)
        result = unified_diff(
            l,
            r,
            fromfile=f"{left.filename} {key}",
            tofile=f"{right.filename} {key}",
            n=n,
        )
        yield result


def diff_id(left: ObjectMap, right: ObjectMap, n: int = 3):
    return unified_diff(
        [f"{x}\n" for x in left.keys()],
        [f"{x}\n" for x in right.keys()],
        fromfile=f"{left.filename}",
        tofile=f"{right.filename}",
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

    if args.id:
        sys.stdout.writelines(diff_id(lmap, rmap, n=args.context))
    else:
        for d in diff(lmap, rmap, n=args.context):
            sys.stdout.writelines(d)
